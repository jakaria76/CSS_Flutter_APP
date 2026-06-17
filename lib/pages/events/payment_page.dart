import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

class PaymentPage extends StatefulWidget {
  final int eventId;
  final double price;
  final Map<String, dynamic> formData;

  const PaymentPage({
    super.key,
    required this.eventId,
    required this.price,
    required this.formData,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final supabase            = Supabase.instance.client;
  final _formKey            = GlobalKey<FormState>();
  final paymentNumberCtrl   = TextEditingController();
  final transactionCtrl     = TextEditingController();

  XFile? screenshotFile;
  bool loading = false;

  // ✅ আগে এগুলো hardcoded constant ছিল, এখন event থেকে আসবে (nullable)
  String? bkashNumber;
  String? nagadNumber;
  bool _loadingNumbers = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentNumbers();
  }

  /// ✅ Event-এর bkash/nagad number লোড করে।
  /// যদি event তৈরির সময় UI থেকেই বানানো event map টা formData-এ পাস করা থাকে
  /// (যেমন event_bkash_number / event_nagad_number key দিয়ে) তাহলে সেটা ব্যবহার হবে,
  /// না থাকলে সরাসরি events টেবিল থেকে fetch করা হবে।
  Future<void> _loadPaymentNumbers() async {
    try {
      final passedBkash = widget.formData['event_bkash_number'] as String?;
      final passedNagad = widget.formData['event_nagad_number'] as String?;

      if (passedBkash != null || passedNagad != null) {
        bkashNumber = passedBkash;
        nagadNumber = passedNagad;
      } else {
        final data = await supabase
            .from('events')
            .select('bkash_number, nagad_number')
            .eq('id', widget.eventId)
            .maybeSingle();
        bkashNumber = data?['bkash_number'] as String?;
        nagadNumber = data?['nagad_number'] as String?;
      }
    } catch (e) {
      debugPrint('Failed to load payment numbers: $e');
    } finally {
      if (mounted) setState(() => _loadingNumbers = false);
    }
  }

  @override
  void dispose() {
    paymentNumberCtrl.dispose();
    transactionCtrl.dispose();
    super.dispose();
  }

  Future<void> pickScreenshot() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => screenshotFile = picked);
  }

  Future<String?> _uploadScreenshot(String userId) async {
    if (screenshotFile == null) return null;
    try {
      final bytes = await screenshotFile!.readAsBytes();
      final path  = '$userId/pay_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('payment-screenshots').uploadBinary(
        path, bytes,
        fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
      );
      return supabase.storage.from('payment-screenshots').getPublicUrl(path);
    } catch (e) {
      debugPrint('Screenshot upload error: $e');
      return null;
    }
  }

  Future<String?> _uploadUserImage(String userId) async {
    final pickedFile = widget.formData['user_image_file'];
    if (pickedFile == null) return null;
    try {
      final bytes = await pickedFile.readAsBytes();
      final path  =
          '$userId/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('user-images').uploadBinary(path, bytes,
          fileOptions: const FileOptions(upsert: true));
      return supabase.storage.from('user-images').getPublicUrl(path);
    } catch (_) {
      return null;
    }
  }

  Future<void> submitPayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (screenshotFile == null) {
      SC.toast(context, SC.tr('screenshotRequired'), SC.orange);
      return;
    }
    setState(() => loading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final screenshotUrl = await _uploadScreenshot(user.id);
      final userImageUrl  = await _uploadUserImage(user.id);

      await supabase.from('event_registrations').insert({
        'event_id': widget.eventId,
        'user_id': user.id,
        'full_name': widget.formData['full_name'],
        'mobile': widget.formData['mobile'],
        'email': widget.formData['email'],
        'gender': widget.formData['gender'],
        'institute_name': widget.formData['institute_name'],
        'class_name': widget.formData['class_name'],
        'why_join': widget.formData['why_join'],
        'will_volunteer': widget.formData['will_volunteer'],
        'payment_method': 'bKash/Nagad',
        'payment_number': paymentNumberCtrl.text.trim(),
        'transaction_id': transactionCtrl.text.trim(),
        'payment_screenshot_url': screenshotUrl,
        'payment_status': 'pending',
        'user_image_url': userImageUrl,
      });

      if (!mounted) return;
      Navigator.popUntil(context, (route) => route.isFirst);
      SC.toast(context, SC.tr('submittedSuccess'), SC.green);
    } catch (e) {
      SC.toast(context, 'Failed: $e', SC.red);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: SC.themeModeNotifier,
      builder: (context, _, __) => ValueListenableBuilder<String>(
        valueListenable: SC.languageNotifier,
        builder: (context, __, ___) => _buildPage(),
      ),
    );
  }

  Widget _buildPage() {
    final isDark       = SC.isDark;
    final textColor    = isDark ? Colors.white : const Color(0xFF1A2332);
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF4A5568);
    final borderColor  = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.08);
    final cardColor    = isDark ? SC.cardBg : Colors.white;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(SC.tr('payment').toUpperCase(),
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: SC.cyan)),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  color: textColor, size: 18),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(gradient: SC.currentGradient),
          child: Stack(
            children: [
              Positioned(
                  top: 100, right: -60,
                  child: SC.blob(200, SC.cyan.withValues(alpha: 0.07))),
              Positioned(
                  bottom: 100, left: -60,
                  child: SC.blob(180, SC.purple.withValues(alpha: 0.07))),
              SafeArea(
                child: (loading || _loadingNumbers)
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: SC.cyan),
                      const SizedBox(height: 20),
                      Text(
                          loading
                              ? SC.tr('submitting')
                              : SC.tr('loading'),
                          style: TextStyle(
                              color: textColor.withValues(alpha: 0.5))),
                    ],
                  ),
                )
                    : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  physics: const BouncingScrollPhysics(),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAmountCard(isDark, textColor, subTextColor, borderColor),
                        const SizedBox(height: 24),

                        // ✅ যদি দুটো নম্বরই null হয়, পুরো instructions card hide এবং warning দেখাবে
                        if (bkashNumber != null || nagadNumber != null) ...[
                          _sectionTitle(SC.tr('paymentInstructions')),
                          _buildInstructionsCard(isDark, textColor, subTextColor, borderColor, cardColor),
                        ] else
                          _buildNoPaymentMethodWarning(textColor),

                        const SizedBox(height: 24),
                        _sectionTitle(SC.tr('yourPaymentDetails')),
                        _buildPaymentFormCard(isDark, textColor, subTextColor, borderColor, cardColor),
                        const SizedBox(height: 24),
                        _sectionTitle(SC.tr('paymentScreenshot')),
                        _buildScreenshotPicker(isDark, textColor, subTextColor, borderColor),
                        const SizedBox(height: 40),
                        _buildSubmitButton(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoPaymentMethodWarning(Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SC.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SC.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: SC.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(SC.tr('noPaymentMethod'),
                style: TextStyle(
                    color: textColor.withValues(alpha: 0.8),
                    fontSize: 13,
                    height: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard(bool isDark, Color textColor, Color subTextColor,
      Color borderColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              SC.cyan.withValues(alpha: 0.15),
              SC.blue.withValues(alpha: 0.1),
            ]),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: SC.cyan.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(SC.tr('amountToPay').toUpperCase(),
                  style: TextStyle(
                      color: subTextColor.withValues(alpha: 0.6),
                      fontSize: 11, letterSpacing: 1.5,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('৳ ${widget.price.toInt()}',
                  style: TextStyle(
                      color: SC.cyan,
                      fontSize: 48, fontWeight: FontWeight.w900, height: 1)),
              const SizedBox(height: 8),
              Text(SC.tr('sendMoneyInstruction'),
                  style: TextStyle(
                      color: textColor.withValues(alpha: 0.5), fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionsCard(bool isDark, Color textColor, Color subTextColor,
      Color borderColor, Color cardColor) {
    final children = <Widget>[];

    if (bkashNumber != null) {
      children.add(_paymentMethodRow('bKash', bkashNumber!,
          const Color(0xFFE2136E), Icons.account_balance_wallet, textColor));
    }

    if (bkashNumber != null && nagadNumber != null) {
      children.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Divider(color: borderColor, height: 1),
      ));
    }

    if (nagadNumber != null) {
      children.add(_paymentMethodRow('Nagad', nagadNumber!,
          const Color(0xFFFF6B00), Icons.account_balance_wallet_outlined, textColor));
    }

    children.add(const SizedBox(height: 16));
    children.add(
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: SC.amber.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: SC.amber.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: SC.amber, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(SC.tr('instructionNote'),
                  style: TextStyle(
                      color: SC.amber.withValues(alpha: 0.9),
                      fontSize: 12, height: 1.6)),
            ),
          ],
        ),
      ),
    );

    return _glassCard(isDark, borderColor, cardColor, children);
  }

  Widget _paymentMethodRow(String method, String number, Color color,
      IconData icon, Color textColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(method,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 0.5)),
              Text(number,
                  style: TextStyle(
                      color: textColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5)),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: number));
            SC.toast(context, '$method ${SC.tr('copyMsg')}', SC.cyan);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.copy_rounded, color: color, size: 14),
                const SizedBox(width: 4),
                Text(SC.tr('copy'),
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentFormCard(bool isDark, Color textColor, Color subTextColor,
      Color borderColor, Color cardColor) {
    return _glassCard(isDark, borderColor, cardColor, [
      _inputField(
        ctrl: paymentNumberCtrl,
        label: SC.tr('yourPaymentNumber'),
        icon: Icons.phone_android_outlined,
        type: TextInputType.phone,
        hint: '01XXXXXXXXX',
        textColor: textColor,
        subTextColor: subTextColor,
        borderColor: borderColor,
        isDark: isDark,
      ),
      const SizedBox(height: 16),
      _inputField(
        ctrl: transactionCtrl,
        label: SC.tr('transactionId'),
        icon: Icons.receipt_long_outlined,
        hint: 'e.g. 8ABC123XYZ',
        textColor: textColor,
        subTextColor: subTextColor,
        borderColor: borderColor,
        isDark: isDark,
      ),
    ]);
  }

  Widget _inputField({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    TextInputType type = TextInputType.text,
    String? hint,
    required Color textColor,
    required Color subTextColor,
    required Color borderColor,
    required bool isDark,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      style: TextStyle(color: textColor),
      validator: (v) =>
      v == null || v.trim().isEmpty ? SC.tr('thisFieldRequired') : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: textColor.withValues(alpha: 0.2)),
        labelStyle: TextStyle(
            color: subTextColor.withValues(alpha: 0.6),
            fontSize: 12, fontWeight: FontWeight.w600),
        prefixIcon: Icon(icon,
            color: SC.cyan.withValues(alpha: 0.6), size: 20),
        filled: true,
        fillColor: isDark
            ? Colors.black.withValues(alpha: 0.2)
            : Colors.black.withValues(alpha: 0.04),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: SC.cyan, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
        errorStyle: const TextStyle(color: Colors.redAccent),
      ),
    );
  }

  Widget _buildScreenshotPicker(bool isDark, Color textColor, Color subTextColor,
      Color borderColor) {
    return GestureDetector(
      onTap: pickScreenshot,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: screenshotFile != null
              ? Colors.transparent
              : (isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: screenshotFile != null
                ? SC.cyan.withValues(alpha: 0.6)
                : borderColor,
            width: 2,
          ),
        ),
        child: screenshotFile != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              kIsWeb
                  ? Image.network(screenshotFile!.path,
                  fit: BoxFit.cover)
                  : Image.file(File(screenshotFile!.path),
                  fit: BoxFit.cover),
              Positioned(
                bottom: 12, right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: SC.cyan.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded,
                          color: SC.cyan, size: 14),
                      const SizedBox(width: 6),
                      Text(SC.tr('change'),
                          style: TextStyle(
                              color: SC.cyan,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: SC.cyan.withValues(alpha: 0.1),
                  shape: BoxShape.circle),
              child: Icon(Icons.upload_file_rounded,
                  color: SC.cyan, size: 40),
            ),
            const SizedBox(height: 16),
            Text(SC.tr('uploadScreenshot'),
                style: TextStyle(
                    color: textColor,
                    fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(SC.tr('selectFromGallery'),
                style: TextStyle(
                    color: textColor.withValues(alpha: 0.4),
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: SC.cyan,
          foregroundColor: const Color(0xFF0F2027),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18)),
          elevation: 10,
          shadowColor: SC.cyan.withValues(alpha: 0.4),
        ),
        onPressed: submitPayment,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline_rounded, size: 22),
            const SizedBox(width: 10),
            Text(SC.tr('submitRegistration').toUpperCase(),
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 12, left: 4),
    child: Text(t.toUpperCase(),
        style: TextStyle(
            color: SC.cyan, fontWeight: FontWeight.bold,
            fontSize: 11, letterSpacing: 1.5)),
  );

  Widget _glassCard(bool isDark, Color borderColor, Color cardColor,
      List<Widget> children) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children),
        ),
      ),
    );
  }
}