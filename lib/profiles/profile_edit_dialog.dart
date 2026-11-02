import 'package:flutter/material.dart';

import '../core/profiles/avatars.dart';
import '../core/profiles/profile.dart';
import 'avatar_button.dart';
import 'profile_manager.dart';

class ProfileEditDialog extends StatefulWidget {
  const ProfileEditDialog({super.key, required this.profile});

  static const nicknameKey = ValueKey('edit-nickname');
  static const saveKey = ValueKey('save-profile');

  final Profile profile;

  @override
  State<ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<ProfileEditDialog> {
  late final _nickname = TextEditingController(text: widget.profile.nickname);
  late String _avatar = widget.profile.avatar;

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  void _save() {
    final nickname = _nickname.text.trim();
    if (nickname.isEmpty) return;
    Navigator.pop(context, widget.profile.copyWith(nickname: nickname, avatar: _avatar));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar perfil'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: ProfileEditDialog.nicknameKey,
              controller: _nickname,
              maxLength: ProfileManager.maxNickname,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Apodo'),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final avatar in Avatars.all)
                  AvatarButton(
                    key: ValueKey('edit-avatar-$avatar'),
                    avatar: avatar,
                    size: 56,
                    isSelected: avatar == _avatar,
                    onPressed: () => setState(() => _avatar = avatar),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        TextButton(key: ProfileEditDialog.saveKey, onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }
}
