import 'package:flutter_test/flutter_test.dart';
import 'package:vibehub/api/skills_api.dart';
import 'package:vibehub/ui/widgets/registered_directory_card.dart';

void main() {
  test('getSkillDisplayInfo uses truncated skill description', () {
    final skill = Skill(
      id: 'owner/repo/example-skill@2026.27',
      owner: 'owner',
      repo: 'repo',
      version: '2026.27',
      installCommand: 'install example-skill',
      updateAvailable: false,
      inJsonProjects: '{}',
      description:
          'This description is intentionally long enough to be truncated before rendering in the registered directory card so the skill row remains compact and readable.',
    );

    final info = getSkillDisplayInfo(skill);

    expect(info.description, endsWith('...'));
    expect(info.description.length, lessThanOrEqualTo(140));
    expect(info.description, contains('intentionally long'));
  });
}
