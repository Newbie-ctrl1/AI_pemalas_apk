import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'chat_screen.dart';

class LoginScreen extends StatefulWidget {
	const LoginScreen({super.key});

	@override
	State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
	final _formKey = GlobalKey<FormState>();
	final _usernameController = TextEditingController();
	final _emailController = TextEditingController();
	final _passwordController = TextEditingController();
	bool _isSubmitting = false;
	bool _obscurePassword = true;
	bool _isRegisterMode = false;

	InputDecoration _transparentInputDecoration({
		required String labelText,
		String? hintText,
		Widget? suffixIcon,
	}) {
		return InputDecoration(
			labelText: labelText,
			hintText: hintText,
			suffixIcon: suffixIcon,
			filled: true,
			fillColor: Colors.white.withValues(alpha: 0.14),
			enabledBorder: OutlineInputBorder(
				borderRadius: BorderRadius.circular(14),
				borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
			),
			focusedBorder: OutlineInputBorder(
				borderRadius: BorderRadius.circular(14),
				borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.70), width: 1.4),
			),
			errorBorder: OutlineInputBorder(
				borderRadius: BorderRadius.circular(14),
				borderSide: const BorderSide(color: Colors.redAccent),
			),
			focusedErrorBorder: OutlineInputBorder(
				borderRadius: BorderRadius.circular(14),
				borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
			),
		);
	}

	@override
	void dispose() {
		_usernameController.dispose();
		_emailController.dispose();
		_passwordController.dispose();
		super.dispose();
	}

	Future<void> _submit() async {
		final isValid = _formKey.currentState?.validate() ?? false;
		if (!isValid || _isSubmitting) return;

		setState(() => _isSubmitting = true);

		try {
			if (_isRegisterMode) {
				await ApiService.instance.register(
					username: _usernameController.text.trim(),
					email: _emailController.text.trim(),
					password: _passwordController.text.trim(),
				);

				if (!mounted) return;
				ScaffoldMessenger.of(context).showSnackBar(
					const SnackBar(content: Text('Register berhasil, lanjut login ya.')),
				);
				setState(() => _isRegisterMode = false);
			} else {
				final token = await ApiService.instance.login(
					email: _emailController.text.trim(),
					password: _passwordController.text.trim(),
				);
				await AuthService.instance.saveToken(token);

				if (!mounted) return;
				Navigator.of(context).pushReplacement(
					MaterialPageRoute(builder: (_) => const ChatScreen()),
				);
			}
		} catch (err) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text(err.toString().replaceFirst('Exception: ', ''))),
			);
		} finally {
			if (mounted) setState(() => _isSubmitting = false);
		}
	}

	@override
	Widget build(BuildContext context) {
		final title = _isRegisterMode ? 'Daftar Dulu' : 'Masuk Dulu';
		final subtitle = _isRegisterMode
				? 'Bikin akun dulu biar bisa ngobrol sama AI Pemalas.'
				: 'Jangan masuk. eh tapi ggp deh.';
		final buttonText = _isRegisterMode ? 'Register' : 'Masuk';
		final textTheme = Theme.of(context).textTheme;

		return Scaffold(
			body: Stack(
				fit: StackFit.expand,
				children: [
					Image.asset(
						'assets/images/login_wallpaper.jpeg',
						fit: BoxFit.cover,
						errorBuilder: (context, error, stackTrace) {
							return Container(
								decoration: const BoxDecoration(
									gradient: LinearGradient(
										begin: Alignment.topLeft,
										end: Alignment.bottomRight,
										colors: [Color(0xFFE0F2FE), Color(0xFFF8FAFC)],
									),
								),
							);
						},
					),
					Container(
						decoration: BoxDecoration(
							gradient: LinearGradient(
								begin: Alignment.topCenter,
								end: Alignment.bottomCenter,
								colors: [
									Colors.black.withValues(alpha: 0.30),
									Colors.black.withValues(alpha: 0.45),
								],
							),
						),
					),
					Center(
						child: Padding(
							padding: const EdgeInsets.all(20),
							child: ConstrainedBox(
								constraints: const BoxConstraints(maxWidth: 380),
								child: Card(
									color: Colors.white.withValues(alpha: 0.10),
									shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
									elevation: 0,
									surfaceTintColor: Colors.transparent,
									shadowColor: Colors.transparent,
									child: Padding(
										padding: const EdgeInsets.all(20),
										child: Form(
											key: _formKey,
											child: Column(
												mainAxisSize: MainAxisSize.min,
												crossAxisAlignment: CrossAxisAlignment.stretch,
												children: [
													Text(
														'Sutar si AI Pemalas',
														style: textTheme.headlineSmall?.copyWith(
															fontWeight: FontWeight.w800,
															color: Colors.white,
														),
													),
													const SizedBox(height: 8),
													Text(
														title,
														style: textTheme.titleMedium?.copyWith(color: Colors.white.withValues(alpha: 0.95)),
													),
													const SizedBox(height: 4),
													Text(
														subtitle,
														style: textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
													),
													const SizedBox(height: 18),
													if (_isRegisterMode) ...[
														TextFormField(
															controller: _usernameController,
															style: const TextStyle(color: Colors.white),
															decoration: _transparentInputDecoration(
																labelText: 'Username',
																hintText: 'nama kamu',
															),
															validator: (value) {
																final text = (value ?? '').trim();
																if (_isRegisterMode && text.isEmpty) return 'Username wajib diisi';
																return null;
															},
														),
														const SizedBox(height: 12),
													],
													TextFormField(
														controller: _emailController,
														keyboardType: TextInputType.emailAddress,
														style: const TextStyle(color: Colors.white),
														decoration: _transparentInputDecoration(
															labelText: 'Email',
															hintText: 'kamu@email.com',
														),
														validator: (value) {
															final text = (value ?? '').trim();
															if (text.isEmpty) return 'Email wajib diisi';
															if (!text.contains('@') || !text.contains('.')) return 'Format email kurang valid';
															return null;
														},
													),
													const SizedBox(height: 12),
													TextFormField(
														controller: _passwordController,
														obscureText: _obscurePassword,
														style: const TextStyle(color: Colors.white),
														decoration: _transparentInputDecoration(
															labelText: 'Password',
															suffixIcon: IconButton(
																onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
																icon: Icon(
																	_obscurePassword ? Icons.visibility_off : Icons.visibility,
																	color: Colors.white.withValues(alpha: 0.90),
																),
															),
														),
														validator: (value) {
															final text = (value ?? '').trim();
															if (text.isEmpty) return 'Password wajib diisi';
															if (text.length < 6) return 'Minimal 6 karakter';
															return null;
														},
													),
													const SizedBox(height: 18),
													FilledButton(
														onPressed: _isSubmitting ? null : _submit,
														child: _isSubmitting
																? const SizedBox(
																		height: 18,
																		width: 18,
																		child: CircularProgressIndicator(strokeWidth: 2),
																	)
																: Text(buttonText),
													),
													const SizedBox(height: 8),
													TextButton(
														onPressed: _isSubmitting
																? null
																: () {
																	setState(() {
																		_isRegisterMode = !_isRegisterMode;
																	});
																},
														child: Text(
															_isRegisterMode
																	? 'Sudah punya akun? Masuk aja.'
																	: 'Belum punya akun? Register dulu.',
														),
													),
												],
											),
										),
									),
								),
							),
						),
					),
				],
			),
		);
	}
}
