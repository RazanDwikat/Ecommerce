
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../home/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  late final AnimationController _animCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final ok = await auth.login(
          _emailController.text.trim(), _passwordController.text);
      if (!mounted) return;

      if (ok) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Welcome back!' : auth.errorMessage ?? 'Login failed',
            style: GoogleFonts.dmSans(color: Colors.white)),
        backgroundColor: ok ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: isWide ? _wideLayout() : _narrowLayout(),
          ),
        ),
      ),
    );
  }

  // ── Wide layout (tablet / desktop / web) ──────────────────────────────────

  Widget _wideLayout() {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(flex: 11, child: _leftPanel()),
              Expanded(flex: 10, child: _rightPanel()),
            ],
          ),
        ),
        _footerStrip(),
      ],
    );
  }

  // ── Narrow layout (mobile) ─────────────────────────────────────────────────

  Widget _narrowLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _brandMark(),
          const SizedBox(height: 28),
          Text('Welcome back!',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text('Sign in to continue shopping',
              style: GoogleFonts.dmSans(
                  fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          _formCard(),
          const SizedBox(height: 16),
          _registerRow(),
          const SizedBox(height: 24),
          _footerStrip(),
        ],
      ),
    );
  }

  // ── Left panel ─────────────────────────────────────────────────────────────

  Widget _leftPanel() {
    return Container(
      color: AppColors.sand,
      padding: const EdgeInsets.all(44),
      child: Stack(
        children: [
          // decorative blobs
          Positioned(
            top: -50, right: -50,
            child: _blob(200, AppColors.skyBlue.withOpacity(0.5)),
          ),
          Positioned(
            bottom: -40, left: -40,
            child: _blob(150, AppColors.steelBlue.withOpacity(0.4)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _brandMark(),
              const Spacer(),
              Text('Welcome\nback!',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.15)),
              const SizedBox(height: 12),
              Text('Log in to continue shopping\nthe best products for you.',
                  style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.6)),
              const Spacer(),
              ..._features(),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _brandMark() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: AppColors.steelBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.shopping_bag_outlined,
              size: 18, color: AppColors.textPrimary),
        ),
        const SizedBox(width: 10),
        Text('ShopHub',
            style: GoogleFonts.dmSans(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
      ],
    );
  }

  List<Widget> _features() {
    final items = [
      (Icons.inventory_2_outlined, 'Wide Range',
          'Explore thousands of quality products.'),
      (Icons.sell_outlined, 'Best Prices', 'Get the best deals every day.'),
      (Icons.shield_outlined, 'Secure Shopping',
          'Your security is our top priority.'),
    ];
    return items
        .map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.steelBlue.withOpacity(0.4)),
                    ),
                    child: Icon(e.$1,
                        size: 16, color: AppColors.steelBlue),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.$2,
                          style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      Text(e.$3,
                          style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ))
        .toList();
  }

  // ── Right panel ────────────────────────────────────────────────────────────

  Widget _rightPanel() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 44),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Log in',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              Text('Welcome back! Please enter your details.',
                  style: GoogleFonts.dmSans(
                      fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 28),
              _formCard(),
              const SizedBox(height: 16),
              _socialRow(),
              const SizedBox(height: 16),
              _registerRow(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Shared form card ───────────────────────────────────────────────────────

  Widget _formCard() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _fieldLabel('Email address'),
          const SizedBox(height: 7),
          _buildField(
            controller: _emailController,
            hint: 'Enter your email',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter your email';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 18),
          _fieldLabel('Password'),
          const SizedBox(height: 7),
          _buildField(
            controller: _passwordController,
            hint: 'Enter your password',
            icon: Icons.lock_outline_rounded,
            obscure: _obscure,
            suffix: IconButton(
              icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                  color: AppColors.textSecondary),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter your password';
              if (v.length < 6) return 'At least 6 characters';
              return null;
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: Text('Forgot password?',
                  style: GoogleFonts.dmSans(
                      fontSize: 12, color: AppColors.textSecondary)),
            ),
          ),
          const SizedBox(height: 6),
          Consumer<AuthProvider>(
            builder: (_, auth, __) => _LoginButton(
                onPressed: auth.isLoading ? null : _login,
                isLoading: auth.isLoading),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(text,
        style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: 0.3));
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.dmSans(fontSize: 14, color: AppColors.textHint),
        prefixIcon: Icon(icon, size: 18, color: AppColors.steelBlue),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.sand.withOpacity(0.25),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: AppColors.steelBlue.withOpacity(0.4), width: 1.2)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.steelBlue, width: 1.8)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.error, width: 1.2)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.error, width: 1.8)),
      ),
      validator: validator,
    );
  }

  // ── Social buttons ─────────────────────────────────────────────────────────

  Widget _socialRow() {
    return Column(
      children: [
        Row(children: [
          const Expanded(child: Divider(color: AppColors.divider)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('or continue with',
                style: GoogleFonts.dmSans(
                    fontSize: 12, color: AppColors.textSecondary)),
          ),
          const Expanded(child: Divider(color: AppColors.divider)),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _SocialButton(label: 'Google', icon: Icons.g_mobiledata_rounded)),
          const SizedBox(width: 10),
          Expanded(child: _SocialButton(label: 'Apple', icon: Icons.apple)),
        ]),
      ],
    );
  }

  Widget _registerRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Don't have an account?",
            style: GoogleFonts.dmSans(
                fontSize: 13, color: AppColors.textSecondary)),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6)),
          child: Text('Sign up',
              style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
        ),
      ],
    );
  }

  // ── Footer strip ───────────────────────────────────────────────────────────

  Widget _footerStrip() {
    final items = [
      (Icons.local_shipping_outlined, 'Free Shipping', 'On orders over \$50'),
      (Icons.replay_outlined, 'Easy Returns', '30-day return policy'),
      (Icons.headset_mic_outlined, '24/7 Support', "We're here to help"),
    ];
    return Container(
      color: AppColors.skyBlue.withOpacity(0.3),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items
            .map((e) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(e.$1, size: 20, color: AppColors.steelBlue),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.$2,
                            style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        Text(e.$3,
                            style: GoogleFonts.dmSans(
                                fontSize: 10,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ))
            .toList(),
      ),
    );
  }
}

// ── Gradient login button ──────────────────────────────────────────────────

class _LoginButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  const _LoginButton({this.onPressed, required this.isLoading});

  @override
  State<_LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<_LoginButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                  color: AppColors.steelBlue.withOpacity(0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 5))
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : Text('Log in',
                    style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.4)),
          ),
        ),
      ),
    );
  }
}

// ── Social button ──────────────────────────────────────────────────────────

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SocialButton({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 18, color: AppColors.textPrimary),
      label: Text(label,
          style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: AppColors.steelBlue.withOpacity(0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: AppColors.white,
      ),
    );
  }
}

