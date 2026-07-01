import 'package:vibehub/api/skills_api.dart';
import 'package:vibehub/ui/bloc/skills_catalog/skills_catalog_state.dart';

sealed class SkillsCatalogEvent {
  const SkillsCatalogEvent();
}

class SkillsCatalogStarted extends SkillsCatalogEvent {
  const SkillsCatalogStarted();
}

class SkillsCatalogOwnerSelected extends SkillsCatalogEvent {
  const SkillsCatalogOwnerSelected(this.owner);

  final String owner;
}

class SkillsCatalogRepoSelected extends SkillsCatalogEvent {
  const SkillsCatalogRepoSelected(this.repo);

  final String repo;
}

class SkillsCatalogOwnerQueryChanged extends SkillsCatalogEvent {
  const SkillsCatalogOwnerQueryChanged(this.query);

  final String query;
}

class SkillsCatalogRepoQueryChanged extends SkillsCatalogEvent {
  const SkillsCatalogRepoQueryChanged(this.query);

  final String query;
}

class SkillsCatalogSkillQueryChanged extends SkillsCatalogEvent {
  const SkillsCatalogSkillQueryChanged(this.query);

  final String query;
}

class SkillsCatalogSkillFilterChanged extends SkillsCatalogEvent {
  const SkillsCatalogSkillFilterChanged(this.filter);

  final SkillListFilter filter;
}

class SkillsCatalogInstallAllRequested extends SkillsCatalogEvent {
  const SkillsCatalogInstallAllRequested(this.items);

  final List<SkillFeedItem> items;
}

class SkillsCatalogInstallRequested extends SkillsCatalogEvent {
  const SkillsCatalogInstallRequested(this.item);

  final SkillFeedItem item;
}

class SkillsCatalogUpdateRequested extends SkillsCatalogEvent {
  const SkillsCatalogUpdateRequested(this.item);

  final SkillFeedItem item;
}

class SkillsCatalogUninstallRequested extends SkillsCatalogEvent {
  const SkillsCatalogUninstallRequested(this.item);

  final SkillFeedItem item;
}

class SkillsCatalogUninstallVersionRequested extends SkillsCatalogEvent {
  const SkillsCatalogUninstallVersionRequested(this.skill);

  final Skill skill;
}
