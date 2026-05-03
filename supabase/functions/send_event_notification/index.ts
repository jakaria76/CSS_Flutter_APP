import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;


// ✅ তোমার logo URL এখানে দাও
const LOGO_URL = "https://dkhigqqmxzlyrbvxrsqa.supabase.co/storage/v1/object/public/assets/logo.jpg";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// ✅ Rate limit fix: প্রতিটা email এর মাঝে 600ms delay
const delay = (ms: number) => new Promise((r) => setTimeout(r, ms));

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // ── Auth verify ──
    const authHeader = req.headers.get("Authorization");
    if (!authHeader?.startsWith("Bearer ")) {
      return new Response(JSON.stringify({ error: "Missing authorization header" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const token = authHeader.replace("Bearer ", "");
    const userSupabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: `Bearer ${token}` } },
      auth: { autoRefreshToken: false, persistSession: false },
    });

    const { data: { user }, error: authError } = await userSupabase.auth.getUser();
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // ── Admin check ──
    const adminSupabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    const { data: profile } = await adminSupabase
      .from("profiles")
      .select("role")
      .eq("id", user.id)
      .single();

    if (profile?.role !== "admin") {
      return new Response(JSON.stringify({ error: "Only admins can send notifications" }), {
        status: 403,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // ── Parse body ──
    const body = await req.json();
    const { title, description, event_id, banner_url, venue, start_datetime, price } = body;

    console.log("📦 Received:", JSON.stringify({ title, event_id, venue, start_datetime, price }));

    if (!title || !description || !event_id) {
      return new Response(JSON.stringify({ error: "Missing required fields" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // ── Format date ──
    let formattedDate = "তারিখ জানানো হয়নি";
    let formattedTime = "";
    if (start_datetime) {
      const dt = new Date(start_datetime);
      formattedDate = dt.toLocaleDateString("bn-BD", {
        year: "numeric",
        month: "long",
        day: "numeric",
        weekday: "long",
      });
      formattedTime = dt.toLocaleTimeString("bn-BD", {
        hour: "2-digit",
        minute: "2-digit",
        hour12: true,
      });
    }

    const venueText = venue && venue.trim() !== "" ? venue.trim() : "স্থান জানানো হয়নি";
    const priceText = price && Number(price) > 0 ? `৳${price}` : "বিনামূল্যে";

    console.log(`📋 venue: ${venueText}, date: ${formattedDate}, price: ${priceText}`);

    // ── Fetch all users (max 1000) ──
    const { data: users, error: usersError } = await adminSupabase.auth.admin.listUsers({
      perPage: 1000,
    });
    if (usersError) throw usersError;

    const emails: string[] = users.users
      .map((u) => u.email)
      .filter((e): e is string => !!e && e.trim() !== "");

    console.log(`👥 Total emails: ${emails.length}`);

    if (emails.length === 0) {
      return new Response(JSON.stringify({ success: true, sent: 0, total: 0 }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const html = buildEmailHtml({
      title,
      description,
      event_id,
      banner_url,
      venueText,
      formattedDate,
      formattedTime,
      priceText,
    });

    // ── ✅ একটা একটা করে পাঠাও, মাঝে 600ms delay ──
    let sent = 0;
    let failed = 0;

    for (let i = 0; i < emails.length; i++) {
      const email = emails[i];
      try {
        const res = await fetch("https://api.resend.com/emails", {
          method: "POST",
          headers: {
            Authorization: `Bearer ${RESEND_API_KEY}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            from: FROM_EMAIL,
            to: [email],
            subject: `নতুন ইভেন্ট: ${title} — CSS`,
            html,
            headers: {
              "X-Entity-Ref-ID": `css-event-${event_id}-${email}`,
              "List-Unsubscribe": `<mailto:noreply@consciousstudentsociety.site?subject=unsubscribe>`,
              "List-Unsubscribe-Post": "List-Unsubscribe=One-Click",
            },
          }),
        });

        if (res.ok) {
          sent++;
          console.log(`✅ [${i + 1}/${emails.length}] Sent to: ${email}`);
        } else {
          const err = await res.json();
          failed++;
          console.error(`❌ [${i + 1}/${emails.length}] Failed for ${email}:`, JSON.stringify(err));
        }
      } catch (e) {
        failed++;
        console.error(`❌ [${i + 1}/${emails.length}] Exception for ${email}:`, e);
      }

      // ✅ শেষ email এর পরে delay দরকার নেই
      if (i < emails.length - 1) {
        await delay(600); // 600ms = safe under 2/sec limit
      }
    }

    console.log(`📊 Done: ${sent} sent, ${failed} failed / ${emails.length} total`);

    return new Response(
      JSON.stringify({ success: true, sent, failed, total: emails.length }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("💥 Fatal error:", err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

// ══════════════════════════════════════════════════════
// EMAIL TEMPLATE - সব info সহ + Logo
// ══════════════════════════════════════════════════════
function buildEmailHtml(p: {
  title: string;
  description: string;
  event_id: number | string;
  banner_url?: string;
  venueText: string;
  formattedDate: string;
  formattedTime: string;
  priceText: string;
}): string {
  const bannerHtml = p.banner_url
    ? `<tr><td style="padding:0;line-height:0;">
        <img src="${p.banner_url}" alt="${p.title}" width="600"
             style="width:100%;max-height:300px;object-fit:cover;display:block;"/>
       </td></tr>`
    : "";

  return `<!DOCTYPE html>
<html lang="bn" xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1.0"/>
<title>${p.title}</title>
<style>
body{margin:0;padding:0;background:#0d1117;font-family:Arial,sans-serif;}
a{color:#00FFFF;text-decoration:none;}
</style>
</head>
<body style="margin:0;padding:0;background:#0d1117;">

<!-- Preheader -->
<div style="display:none;max-height:0;overflow:hidden;font-size:1px;color:#0d1117;">
CSS ইভেন্ট: ${p.title} | ${p.venueText} | ${p.formattedDate}
</div>

<table cellpadding="0" cellspacing="0" border="0" width="100%"
       style="background:#0d1117;padding:24px 12px 48px;">
<tr><td align="center">

<table cellpadding="0" cellspacing="0" border="0"
       style="max-width:600px;width:100%;border-radius:20px;overflow:hidden;
              border:1px solid rgba(0,255,255,0.18);
              background:linear-gradient(170deg,#0f1f2e 0%,#0c1820 60%,#0d1a26 100%);">

  <!-- TOP GRADIENT BAR -->
  <tr>
    <td style="height:4px;line-height:4px;font-size:4px;
               background:linear-gradient(90deg,#0077b6,#00FFFF,#0096c7);">&nbsp;</td>
  </tr>

  <!-- LOGO + ORG HEADER -->
  <tr>
    <td style="padding:30px 40px 24px;text-align:center;
               border-bottom:1px solid rgba(255,255,255,0.07);">
      <img src="${LOGO_URL}" alt="CSS Logo" width="72" height="72"
           style="border-radius:50%;border:2px solid rgba(0,255,255,0.35);
                  margin-bottom:14px;display:block;margin-left:auto;margin-right:auto;"/>
      <div style="font-size:9px;letter-spacing:3.5px;color:rgba(0,255,255,0.85);
                  font-weight:700;margin-bottom:6px;">
        CONSCIOUS STUDENT SOCIETY
      </div>
      <div style="font-size:11px;color:rgba(255,255,255,0.2);letter-spacing:2px;">
        নতুন ঘোষণা &nbsp;&bull;&nbsp; New Announcement
      </div>
    </td>
  </tr>

  <!-- BANNER IMAGE -->
  ${bannerHtml}

  <!-- MAIN BODY -->
  <tr>
    <td style="padding:32px 40px 28px;">

      <!-- Tag pill -->
      <div style="display:inline-block;background:rgba(0,255,255,0.1);
                  border:1px solid rgba(0,255,255,0.28);border-radius:20px;
                  padding:5px 15px;margin-bottom:18px;">
        <span style="font-size:10px;font-weight:700;letter-spacing:2px;color:#00FFFF;">
          🎯 &nbsp;CSS EVENT
        </span>
      </div>

      <!-- Event Title -->
      <h1 style="margin:0 0 6px;font-size:26px;font-weight:700;color:#ffffff;
                 line-height:1.3;padding-left:15px;border-left:3px solid #00FFFF;">
        ${p.title}
      </h1>

      <!-- Divider -->
      <div style="height:1px;margin:18px 0;
                  background:linear-gradient(90deg,rgba(0,255,255,0.35),rgba(0,255,255,0));"></div>

      <!-- Description -->
      <p style="margin:0 0 26px;font-size:15px;line-height:1.9;
                color:rgba(255,255,255,0.7);">
        ${p.description}
      </p>

      <!-- ✅ Info Box — Venue + Date + Price সব আছে -->
      <table cellpadding="0" cellspacing="0" width="100%"
             style="background:rgba(0,0,0,0.3);border:1px solid rgba(255,255,255,0.08);
                    border-radius:14px;overflow:hidden;margin-bottom:28px;">
        <tbody>

          <!-- Venue -->
          <tr>
            <td style="padding:14px 18px;border-bottom:1px solid rgba(255,255,255,0.06);">
              <table cellpadding="0" cellspacing="0" width="100%">
                <tr>
                  <td width="36" valign="middle">
                    <div style="width:28px;height:28px;background:rgba(0,255,255,0.08);
                                 border-radius:8px;text-align:center;line-height:28px;font-size:14px;">
                      📍
                    </div>
                  </td>
                  <td style="padding-left:12px;">
                    <div style="font-size:9px;letter-spacing:1.5px;
                                 color:rgba(255,255,255,0.3);margin-bottom:4px;">VENUE</div>
                    <div style="font-size:14px;color:#ffffff;font-weight:600;">${p.venueText}</div>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Date & Time -->
          <tr>
            <td style="padding:14px 18px;border-bottom:1px solid rgba(255,255,255,0.06);">
              <table cellpadding="0" cellspacing="0" width="100%">
                <tr>
                  <td width="36" valign="middle">
                    <div style="width:28px;height:28px;background:rgba(0,255,255,0.08);
                                 border-radius:8px;text-align:center;line-height:28px;font-size:14px;">
                      📅
                    </div>
                  </td>
                  <td style="padding-left:12px;">
                    <div style="font-size:9px;letter-spacing:1.5px;
                                 color:rgba(255,255,255,0.3);margin-bottom:4px;">DATE & TIME</div>
                    <div style="font-size:14px;color:#ffffff;font-weight:600;">${p.formattedDate}</div>
                    <div style="font-size:12px;color:rgba(255,255,255,0.45);margin-top:2px;">${p.formattedTime}</div>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Price -->
          <tr>
            <td style="padding:14px 18px;">
              <table cellpadding="0" cellspacing="0" width="100%">
                <tr>
                  <td width="36" valign="middle">
                    <div style="width:28px;height:28px;background:rgba(0,255,255,0.08);
                                 border-radius:8px;text-align:center;line-height:28px;font-size:14px;">
                      🎟
                    </div>
                  </td>
                  <td style="padding-left:12px;">
                    <div style="font-size:9px;letter-spacing:1.5px;
                                 color:rgba(255,255,255,0.3);margin-bottom:4px;">Registration Fee</div>
                    <div style="font-size:16px;color:#00FFFF;font-weight:700;">${p.priceText}</div>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

        </tbody>
      </table>

    </td>
  </tr>

  <!-- FOOTER INFO -->
  <tr>
    <td style="padding:14px 40px;background:rgba(0,0,0,0.3);
               border-top:1px solid rgba(255,255,255,0.05);">
      <table cellpadding="0" cellspacing="0" width="100%">
        <tr>
          <td style="font-size:11px;color:rgba(255,255,255,0.22);">
            📍 Shambhudia Chauhali, Sirajganj
          </td>
          <td align="right" style="font-size:11px;color:rgba(255,255,255,0.22);">
            🌐 consciousstudentsociety.site
          </td>
        </tr>
      </table>
    </td>
  </tr>

  <!-- BOTTOM FOOTER TEXT -->
  <tr>
    <td style="padding:20px 40px 22px;text-align:center;">
      <p style="margin:0 0 5px;font-size:10px;font-weight:700;letter-spacing:2px;
                 color:rgba(255,255,255,0.12);">
        &copy; 2026 CONSCIOUS STUDENT SOCIETY
      </p>
      <p style="margin:0;font-size:10px;color:rgba(255,255,255,0.08);">
        তুমি এই email পাচ্ছ কারণ তুমি CSS App-এর একজন সদস্য।
      </p>
    </td>
  </tr>

  <!-- BOTTOM GRADIENT BAR -->
  <tr>
    <td style="height:3px;line-height:3px;font-size:3px;
               background:linear-gradient(90deg,rgba(0,119,182,0),#00FFFF,rgba(0,150,199,0));">&nbsp;</td>
  </tr>

</table>
</td></tr>
</table>
</body>
</html>`;
}