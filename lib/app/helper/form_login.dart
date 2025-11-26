import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:koperasi/app/modules/login/controllers/login_controller.dart';

class FormLogin extends StatelessWidget {
  const FormLogin({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<LoginController>();

    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Form(
        key: c.formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: c.emailController,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Enter username or email';
                final trimmed = value.trim();

                // allow fixed username 'koperasi'
                if (trimmed == 'koperasi') return null;

                // otherwise validate as email
                final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
                if (!emailRegex.hasMatch(trimmed)) return 'Invalid email';
                return null;
              },
              decoration: const InputDecoration(
                labelText: 'Username or Email',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            Obx(
              () => TextFormField(
                obscureText: !c.isPasswordVisible.value,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter password';
                  if (value.length < 6) return 'Min 6 chars';
                  return null;
                },
                controller: c.passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      c.isPasswordVisible.value
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: c.togglePassword,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Obx(
              () => CheckboxListTile(
                value: c.rememberMe.value,
                title: const Text('Remember me'),
                onChanged: (value) => c.toggleRemember(value!),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: c.submit,
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Text(
                    'Login Now',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
