import 'package:vibehub/api/skills_api.dart';
import 'package:vibehub/api/skills_catalog_api.dart';
import 'package:vibehub/ui/bloc/skills_catalog/skills_catalog_state.dart';

String skillNameFromVersionedId(String id, String version) {
  final versionSuffix = '@$version';
  if (id.endsWith(versionSuffix)) {
    return id.substring(0, id.length - versionSuffix.length);
  }

  final separator = id.lastIndexOf('@');
  if (separator > 0) {
    return id.substring(0, separator);
  }

  return id;
}

int compareSkillVersions(String first, String second) {
  return first.compareTo(second);
}

Map<String, List<Skill>> buildInstalledSkillVersionsMap(
  List<Skill> installedSkills,
) {
  final installedVersionsMap = <String, List<Skill>>{};

  for (final skill in installedSkills) {
    final fullName = skillNameFromVersionedId(skill.id, skill.version);
    final lastSlash = fullName.lastIndexOf('/');
    final shortName = lastSlash > 0
        ? fullName.substring(lastSlash + 1)
        : fullName;
    final key = skillComparisonKey(
      owner: skill.owner,
      repo: skill.repo,
      name: shortName,
    );
    installedVersionsMap.putIfAbsent(key, () => []).add(skill);
  }

  for (final list in installedVersionsMap.values) {
    list.sort((a, b) => compareSkillVersions(b.version, a.version));
  }

  return installedVersionsMap;
}

List<SkillFeedItem> buildUnifiedSkillFeed(
  List<CatalogSkill> catalogSkills,
  List<Skill> installedSkills,
) {
  final installedVersionsByKey = buildInstalledSkillVersionsMap(
    installedSkills,
  );
  final items = <SkillFeedItem>[];

  for (final catalogSkill in catalogSkills) {
    final comparisonKey = skillComparisonKey(
      owner: catalogSkill.owner,
      repo: catalogSkill.repo,
      name: catalogSkill.name,
    );
    final installedVersions = installedVersionsByKey[comparisonKey] ?? const [];
    final installedSkill = installedVersions.isNotEmpty
        ? installedVersions.first
        : null;
    final localVersion = installedSkill?.version;
    final isInstalled = installedVersions.isNotEmpty;
    final isOutdated =
        localVersion != null &&
        compareSkillVersions(catalogSkill.version, localVersion) > 0;

    items.add(
      SkillFeedItem(
        id: skillIdFor(
          catalogSkill.owner,
          catalogSkill.repo,
          catalogSkill.name,
          catalogSkill.version,
        ),
        comparisonKey: comparisonKey,
        name: catalogSkill.name,
        owner: catalogSkill.owner,
        repo: catalogSkill.repo,
        catalogVersion: catalogSkill.version,
        sha: catalogSkill.sha,
        repoUrl: catalogSkill.repoUrl,
        localVersion: localVersion,
        installCommand: catalogSkill.installCommand,
        isInstalled: isInstalled,
        isOutdated: isOutdated,
        metadata: catalogSkill.metadata,
        installedVersions: installedVersions,
      ),
    );
  }

  items.sort((first, second) {
    final ownerCompare = first.owner.compareTo(second.owner);
    if (ownerCompare != 0) {
      return ownerCompare;
    }
    final repoCompare = first.repo.compareTo(second.repo);
    if (repoCompare != 0) {
      return repoCompare;
    }
    return first.id.compareTo(second.id);
  });

  return items;
}

SkillsCatalogIndex buildSkillsCatalogIndex(List<SkillFeedItem> items) {
  final owners = <String>{};
  final ownerSkillCounts = <String, int>{};
  final repositorySkillCounts = <String, int>{};
  final repositoriesByOwner = <String, Set<String>>{};
  final skillsByOwnerRepo = <String, List<SkillFeedItem>>{};

  for (final item in items) {
    owners.add(item.owner);
    ownerSkillCounts[item.owner] = (ownerSkillCounts[item.owner] ?? 0) + 1;
    final repoKey = _ownerRepoKey(item.owner, item.repo);
    repositorySkillCounts[repoKey] = (repositorySkillCounts[repoKey] ?? 0) + 1;
    repositoriesByOwner
        .putIfAbsent(item.owner, () => <String>{})
        .add(item.repo);
    skillsByOwnerRepo
        .putIfAbsent(
          _ownerRepoKey(item.owner, item.repo),
          () => <SkillFeedItem>[],
        )
        .add(item);
  }

  final sortedOwners = owners.toList()
    ..sort((first, second) {
      final countCompare = (ownerSkillCounts[second] ?? 0).compareTo(
        ownerSkillCounts[first] ?? 0,
      );
      if (countCompare != 0) {
        return countCompare;
      }
      return first.compareTo(second);
    });
  final sortedRepositoriesByOwner = <String, List<String>>{};
  for (final entry in repositoriesByOwner.entries) {
    sortedRepositoriesByOwner[entry.key] = entry.value.toList()
      ..sort((first, second) {
        final countCompare =
            (repositorySkillCounts[_ownerRepoKey(entry.key, second)] ?? 0)
                .compareTo(
                  repositorySkillCounts[_ownerRepoKey(entry.key, first)] ?? 0,
                );
        if (countCompare != 0) {
          return countCompare;
        }
        return first.compareTo(second);
      });
  }

  for (final skills in skillsByOwnerRepo.values) {
    skills.sort((first, second) => first.id.compareTo(second.id));
  }

  return SkillsCatalogIndex(
    owners: sortedOwners,
    ownerSkillCounts: ownerSkillCounts,
    repositorySkillCounts: repositorySkillCounts,
    repositoriesByOwner: sortedRepositoriesByOwner,
    skillsByOwnerRepo: skillsByOwnerRepo,
  );
}

Skill skillFromFeedItem(SkillFeedItem item) {
  return Skill(
    id: skillIdFor(item.owner, item.repo, item.name, item.catalogVersion),
    owner: item.owner,
    repo: item.repo,
    version: item.catalogVersion,
    installCommand: item.installCommand,
    updateAvailable: false,
    inJsonProjects: '{}',
    metadata: {
      ...item.metadata,
      'sha': item.sha,
      'source': item.metadata['source'] ?? '${item.owner}/${item.repo}',
      'sourceType': item.metadata['sourceType'] ?? 'github',
      'skillPath': item.metadata['skillPath'] ?? 'skills/${item.name}/SKILL.md',
    },
  );
}

String _ownerRepoKey(String owner, String repo) {
  return '$owner/$repo';
}
