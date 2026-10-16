import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_haptics.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordObscured = true;
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      AppHaptics.medium();
      context.read<AuthBloc>().add(
            AuthLoginRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              rememberMe: _rememberMe,
            ),
          );
    } else {
      AppHaptics.error();
    }
  }

  void _showForgotPasswordSheet() {
    AppHaptics.light();
    final resetController = TextEditingController(text: _emailController.text);

    AppBottomSheet.show(
      context: context,
      title: 'Reset Password',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Enter your verified email address to receive simulation password recovery instructions.',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Institutional Email',
            hintText: 'name@institution.com',
            controller: resetController,
            prefixIcon: const Icon(Icons.email_outlined, size: 18),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 24),
          AppButton(
            text: 'Send Recovery Link',
            onPressed: () {
              AppHaptics.medium();
              Navigator.pop(context);
              context.read<AuthBloc>().add(
                    AuthResetPasswordRequested(email: resetController.text.trim()),
                  );
            },
          ),
        ],
      ),
    );
  }

  void _showCreateAccountDialog() {
    AppHaptics.light();
    AppDialog.show(
      context: context,
      type: AppDialogType.info,
      title: 'Practice Account Notice',
      message:
          'This institutional trading terminal provides simulated accounts (\$100,000 USD virtual capital). Enter your credentials to access the terminal.',
      primaryButtonText: 'Understood',
      onPrimaryPressed: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailure) {
          AppHaptics.error();
          AppDialog.show(
            context: context,
            type: AppDialogType.danger,
            title: 'Authentication Failed',
            message: state.message,
            primaryButtonText: 'Try Again',
            onPrimaryPressed: () {},
          );
        } else if (state is Authenticated) {
          AppHaptics.success();
        } else if (state is AuthPasswordResetSuccess) {
          AppHaptics.success();
          AppDialog.show(
            context: context,
            type: AppDialogType.success,
            title: 'Recovery Email Sent',
            message:
                'Password recovery instructions were dispatched to ${state.email}. Please follow the link to restore access.',
            primaryButtonText: 'Understood',
            onPrimaryPressed: () {},
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Trading Candle Semi-Circle Header Area
                _TradingCandleHeader(isDark: isDark),

                // Form Container
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Welcome Title
                        Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sign in to access your portfolio and live market simulation.',
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Email Field
                        AppTextField(
                          label: 'Email Address',
                          hintText: 'Enter your email address',
                          controller: _emailController,
                          prefixIcon: const Icon(Icons.email_outlined, size: 18),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email address is required.';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email address.';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        // Password Field
                        AppTextField(
                          label: 'Password',
                          hintText: 'Enter your password',
                          controller: _passwordController,
                          obscureText: _isPasswordObscured,
                          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordObscured
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 18,
                              color: textSecondary,
                            ),
                            onPressed: () {
                              AppHaptics.light();
                              setState(() => _isPasswordObscured = !_isPasswordObscured);
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required.';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters.';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        // Remember Me & Forgot Password Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap: () {
                                AppHaptics.selection();
                                setState(() => _rememberMe = !_rememberMe);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        activeColor: AppColors.primaryBlue,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        onChanged: (val) {
                                          AppHaptics.selection();
                                          setState(() => _rememberMe = val ?? true);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Remember me',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: _showForgotPasswordSheet,
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // Submit Button
                        AppButton(
                          text: 'Sign In to Terminal',
                          isLoading: isLoading,
                          onPressed: _submitLogin,
                        ),

                        const SizedBox(height: 20),

                        // Sign Up Option
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(color: textSecondary, fontSize: 13),
                            ),
                            GestureDetector(
                              onTap: _showCreateAccountDialog,
                              child: const Text(
                                'Open Paper Account',
                                style: TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Semi-Circle Top Header with Stylized Trading Candlestick Artwork
class _TradingCandleHeader extends StatelessWidget {
  final bool isDark;

  const _TradingCandleHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final totalHeight = 220.0 + topPadding;

    return ClipPath(
      clipper: _SemiCircleClipper(),
      child: Container(
        height: totalHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF131A26),
                    const Color(0xFF0F1520),
                    const Color(0xFF0A0D14),
                  ]
                : [
                    const Color(0xFFE8EEF8),
                    const Color(0xFFF1F5F9),
                    const Color(0xFFF8FAFC),
                  ],
          ),
        ),
        child: Stack(
          children: [
            // Candlestick Pattern Custom Paint
            Positioned.fill(
              child: CustomPaint(
                painter: _CandlestickPatternPainter(isDark: isDark),
              ),
            ),

            // Subtle Glowing Radial Gradient
            Positioned(
              top: topPadding + 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primaryBlue.withValues(alpha: isDark ? 0.22 : 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Header Content (Logo + Badge + Title)
            Positioned(
              top: topPadding + 20,
              left: 24,
              right: 24,
              child: Column(
                children: [
                  // Luminous Candlestick Terminal Icon
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF151C28)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primaryBlue.withValues(alpha: 0.45),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withValues(alpha: isDark ? 0.35 : 0.15),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Mini Green Candle
                          Container(
                            width: 5,
                            height: 22,
                            decoration: BoxDecoration(
                              color: AppColors.bullGreen,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Mini Red Candle
                          Container(
                            width: 5,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppColors.bearRed,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Tall Green Breakout Candle
                          Container(
                            width: 5,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.bullGreen,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Brand Title
                  Text(
                    'TRADING APP',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.2,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Market Pulse Chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1B2332)
                          : Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.bullGreen.withValues(alpha: 0.35),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.bullGreen,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'MARKETS ACTIVE • LIVE FEED',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: isDark
                                ? AppColors.bullGreen
                                : AppColors.bullGreenLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Smooth Semi-Circle / Arc Clipper for the top header
class _SemiCircleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 36);

    // Convex semi-circle curve across the bottom
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 12,
      size.width,
      size.height - 36,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Custom Painter drawing stylized trading candlesticks & grid lines
class _CandlestickPatternPainter extends CustomPainter {
  final bool isDark;

  _CandlestickPatternPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04)
      ..strokeWidth = 0.8;

    // Draw Subtle Horizontal Grid Lines
    for (double y = 40; y < size.height; y += 38) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Candlestick Definitions: (centerX, bodyTop, bodyHeight, wickTop, wickBottom, isBullish)
    final candles = [
      (size.width * 0.06, 110.0, 24.0, 96.0, 142.0, true),
      (size.width * 0.14, 122.0, 20.0, 114.0, 148.0, false),
      (size.width * 0.22, 105.0, 28.0, 92.0, 140.0, true),
      (size.width * 0.30, 95.0, 22.0, 84.0, 126.0, true),
      (size.width * 0.70, 88.0, 26.0, 74.0, 122.0, true),
      (size.width * 0.78, 102.0, 18.0, 94.0, 128.0, false),
      (size.width * 0.86, 78.0, 32.0, 62.0, 118.0, true),
      (size.width * 0.94, 68.0, 36.0, 52.0, 112.0, true),
    ];

    for (final c in candles) {
      final cx = c.$1;
      final bodyTop = c.$2;
      final bodyHeight = c.$3;
      final wickTop = c.$4;
      final wickBottom = c.$5;
      final isBull = c.$6;

      final color = (isBull ? AppColors.bullGreen : AppColors.bearRed)
          .withValues(alpha: isDark ? 0.38 : 0.28);

      final wickPaint = Paint()
        ..color = color
        ..strokeWidth = 1.2;

      // Draw Upper and Lower Wick
      canvas.drawLine(Offset(cx, wickTop), Offset(cx, wickBottom), wickPaint);

      // Draw Candle Body
      final bodyRect = Rect.fromCenter(
        center: Offset(cx, bodyTop + bodyHeight / 2),
        width: 10,
        height: bodyHeight,
      );

      final bodyPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(bodyRect, const Radius.circular(2)),
        bodyPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CandlestickPatternPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
