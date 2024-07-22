import 'package:drift/internal/versioned_schema.dart' as i0;
import 'package:drift/drift.dart' as i1;
import 'package:drift/drift.dart'; // ignore_for_file: type=lint,unused_import

// GENERATED BY drift_dev, DO NOT MODIFY.
final class Schema2 extends i0.VersionedSchema {
  Schema2({required super.database}) : super(version: 2);
  @override
  late final List<i1.DatabaseSchemaEntity> entities = [
    accounts,
    favorites,
    localSubscriptions,
    userLabels,
  ];
  late final Shape0 accounts = Shape0(
      source: i0.VersionedTable(
        entityName: 'accounts',
        withoutRowId: false,
        isStrict: false,
        tableConstraints: [],
        columns: [
          _column_0,
          _column_1,
          _column_2,
          _column_3,
          _column_4,
          _column_5,
        ],
        attachedDatabase: database,
      ),
      alias: null);
  late final Shape1 favorites = Shape1(
      source: i0.VersionedTable(
        entityName: 'favorites',
        withoutRowId: false,
        isStrict: false,
        tableConstraints: [],
        columns: [
          _column_0,
          _column_6,
          _column_7,
        ],
        attachedDatabase: database,
      ),
      alias: null);
  late final Shape2 localSubscriptions = Shape2(
      source: i0.VersionedTable(
        entityName: 'local_subscriptions',
        withoutRowId: false,
        isStrict: false,
        tableConstraints: [],
        columns: [
          _column_0,
          _column_8,
          _column_9,
          _column_10,
          _column_11,
        ],
        attachedDatabase: database,
      ),
      alias: null);
  late final Shape3 userLabels = Shape3(
      source: i0.VersionedTable(
        entityName: 'user_labels',
        withoutRowId: false,
        isStrict: false,
        tableConstraints: [],
        columns: [
          _column_0,
          _column_12,
          _column_13,
        ],
        attachedDatabase: database,
      ),
      alias: null);
}

class Shape0 extends i0.VersionedTable {
  Shape0({required super.source, required super.alias}) : super.aliased();
  i1.GeneratedColumn<int> get id => columnsByName['id']! as i1.GeneratedColumn<int>;
  i1.GeneratedColumn<String> get username => columnsByName['username']! as i1.GeneratedColumn<String>;
  i1.GeneratedColumn<String> get jwt => columnsByName['jwt']! as i1.GeneratedColumn<String>;
  i1.GeneratedColumn<String> get instance => columnsByName['instance']! as i1.GeneratedColumn<String>;
  i1.GeneratedColumn<bool> get anonymous => columnsByName['anonymous']! as i1.GeneratedColumn<bool>;
  i1.GeneratedColumn<int> get userId => columnsByName['user_id']! as i1.GeneratedColumn<int>;
}

i1.GeneratedColumn<int> _column_0(String aliasedName) =>
    i1.GeneratedColumn<int>('id', aliasedName, false, hasAutoIncrement: true, type: i1.DriftSqlType.int, defaultConstraints: i1.GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
i1.GeneratedColumn<String> _column_1(String aliasedName) => i1.GeneratedColumn<String>('username', aliasedName, true, type: i1.DriftSqlType.string);
i1.GeneratedColumn<String> _column_2(String aliasedName) => i1.GeneratedColumn<String>('jwt', aliasedName, true, type: i1.DriftSqlType.string);
i1.GeneratedColumn<String> _column_3(String aliasedName) => i1.GeneratedColumn<String>('instance', aliasedName, true, type: i1.DriftSqlType.string);
i1.GeneratedColumn<bool> _column_4(String aliasedName) => i1.GeneratedColumn<bool>('anonymous', aliasedName, false,
    type: i1.DriftSqlType.bool, defaultConstraints: i1.GeneratedColumn.constraintIsAlways('CHECK ("anonymous" IN (0, 1))'), defaultValue: const Constant(false));
i1.GeneratedColumn<int> _column_5(String aliasedName) => i1.GeneratedColumn<int>('user_id', aliasedName, true, type: i1.DriftSqlType.int);

class Shape1 extends i0.VersionedTable {
  Shape1({required super.source, required super.alias}) : super.aliased();
  i1.GeneratedColumn<int> get id => columnsByName['id']! as i1.GeneratedColumn<int>;
  i1.GeneratedColumn<int> get accountId => columnsByName['account_id']! as i1.GeneratedColumn<int>;
  i1.GeneratedColumn<int> get communityId => columnsByName['community_id']! as i1.GeneratedColumn<int>;
}

i1.GeneratedColumn<int> _column_6(String aliasedName) => i1.GeneratedColumn<int>('account_id', aliasedName, false, type: i1.DriftSqlType.int);
i1.GeneratedColumn<int> _column_7(String aliasedName) => i1.GeneratedColumn<int>('community_id', aliasedName, false, type: i1.DriftSqlType.int);

class Shape2 extends i0.VersionedTable {
  Shape2({required super.source, required super.alias}) : super.aliased();
  i1.GeneratedColumn<int> get id => columnsByName['id']! as i1.GeneratedColumn<int>;
  i1.GeneratedColumn<String> get name => columnsByName['name']! as i1.GeneratedColumn<String>;
  i1.GeneratedColumn<String> get title => columnsByName['title']! as i1.GeneratedColumn<String>;
  i1.GeneratedColumn<String> get actorId => columnsByName['actor_id']! as i1.GeneratedColumn<String>;
  i1.GeneratedColumn<String> get icon => columnsByName['icon']! as i1.GeneratedColumn<String>;
}

i1.GeneratedColumn<String> _column_8(String aliasedName) => i1.GeneratedColumn<String>('name', aliasedName, false, type: i1.DriftSqlType.string);
i1.GeneratedColumn<String> _column_9(String aliasedName) => i1.GeneratedColumn<String>('title', aliasedName, false, type: i1.DriftSqlType.string);
i1.GeneratedColumn<String> _column_10(String aliasedName) => i1.GeneratedColumn<String>('actor_id', aliasedName, false, type: i1.DriftSqlType.string);
i1.GeneratedColumn<String> _column_11(String aliasedName) => i1.GeneratedColumn<String>('icon', aliasedName, true, type: i1.DriftSqlType.string);

class Shape3 extends i0.VersionedTable {
  Shape3({required super.source, required super.alias}) : super.aliased();
  i1.GeneratedColumn<int> get id => columnsByName['id']! as i1.GeneratedColumn<int>;
  i1.GeneratedColumn<String> get username => columnsByName['username']! as i1.GeneratedColumn<String>;
  i1.GeneratedColumn<String> get label => columnsByName['label']! as i1.GeneratedColumn<String>;
}

i1.GeneratedColumn<String> _column_12(String aliasedName) => i1.GeneratedColumn<String>('username', aliasedName, false, type: i1.DriftSqlType.string);
i1.GeneratedColumn<String> _column_13(String aliasedName) => i1.GeneratedColumn<String>('label', aliasedName, false, type: i1.DriftSqlType.string);

final class Schema3 extends i0.VersionedSchema {
  Schema3({required super.database}) : super(version: 3);
  @override
  late final List<i1.DatabaseSchemaEntity> entities = [
    accounts,
    favorites,
    localSubscriptions,
    userLabels,
    drafts,
  ];
  late final Shape0 accounts = Shape0(
      source: i0.VersionedTable(
        entityName: 'accounts',
        withoutRowId: false,
        isStrict: false,
        tableConstraints: [],
        columns: [
          _column_0,
          _column_1,
          _column_2,
          _column_3,
          _column_4,
          _column_5,
        ],
        attachedDatabase: database,
      ),
      alias: null);
  late final Shape1 favorites = Shape1(
      source: i0.VersionedTable(
        entityName: 'favorites',
        withoutRowId: false,
        isStrict: false,
        tableConstraints: [],
        columns: [
          _column_0,
          _column_6,
          _column_7,
        ],
        attachedDatabase: database,
      ),
      alias: null);
  late final Shape2 localSubscriptions = Shape2(
      source: i0.VersionedTable(
        entityName: 'local_subscriptions',
        withoutRowId: false,
        isStrict: false,
        tableConstraints: [],
        columns: [
          _column_0,
          _column_8,
          _column_9,
          _column_10,
          _column_11,
        ],
        attachedDatabase: database,
      ),
      alias: null);
  late final Shape3 userLabels = Shape3(
      source: i0.VersionedTable(
        entityName: 'user_labels',
        withoutRowId: false,
        isStrict: false,
        tableConstraints: [],
        columns: [
          _column_0,
          _column_12,
          _column_13,
        ],
        attachedDatabase: database,
      ),
      alias: null);
  late final Shape4 drafts = Shape4(
      source: i0.VersionedTable(
        entityName: 'drafts',
        withoutRowId: false,
        isStrict: false,
        tableConstraints: [],
        columns: [
          _column_0,
          _column_14,
          _column_15,
          _column_16,
          _column_17,
          _column_18,
          _column_19,
        ],
        attachedDatabase: database,
      ),
      alias: null);
}

class Shape4 extends i0.VersionedTable {
  Shape4({required super.source, required super.alias}) : super.aliased();
  i1.GeneratedColumn<int> get id => columnsByName['id']! as i1.GeneratedColumn<int>;
  i1.GeneratedColumn<String> get draftType => columnsByName['draft_type']! as i1.GeneratedColumn<String>;
  i1.GeneratedColumn<int> get existingId => columnsByName['existing_id']! as i1.GeneratedColumn<int>;
  i1.GeneratedColumn<int> get replyId => columnsByName['reply_id']! as i1.GeneratedColumn<int>;
  i1.GeneratedColumn<String> get title => columnsByName['title']! as i1.GeneratedColumn<String>;
  i1.GeneratedColumn<String> get url => columnsByName['url']! as i1.GeneratedColumn<String>;
  i1.GeneratedColumn<String> get body => columnsByName['body']! as i1.GeneratedColumn<String>;
}

i1.GeneratedColumn<String> _column_14(String aliasedName) => i1.GeneratedColumn<String>('draft_type', aliasedName, false, type: i1.DriftSqlType.string);
i1.GeneratedColumn<int> _column_15(String aliasedName) => i1.GeneratedColumn<int>('existing_id', aliasedName, true, type: i1.DriftSqlType.int);
i1.GeneratedColumn<int> _column_16(String aliasedName) => i1.GeneratedColumn<int>('reply_id', aliasedName, true, type: i1.DriftSqlType.int);
i1.GeneratedColumn<String> _column_17(String aliasedName) => i1.GeneratedColumn<String>('title', aliasedName, true, type: i1.DriftSqlType.string);
i1.GeneratedColumn<String> _column_18(String aliasedName) => i1.GeneratedColumn<String>('url', aliasedName, true, type: i1.DriftSqlType.string);
i1.GeneratedColumn<String> _column_19(String aliasedName) => i1.GeneratedColumn<String>('body', aliasedName, true, type: i1.DriftSqlType.string);

final class Schema4 extends i0.VersionedSchema {
  Schema4({required super.database}) : super(version: 4);
  @override
  late final List<i1.DatabaseSchemaEntity> entities = [
    accounts,
    favorites,
    localSubscriptions,
    userLabels,
    drafts,
  ];
  late final Shape0 accounts = Shape0(
      source: i0.VersionedTable(
        entityName: 'accounts',
        withoutRowId: false,
        isStrict: false,
        tableConstraints: [],
        columns: [
          _column_0,
          _column_1,
          _column_2,
          _column_3,
          _column_4,
          _column_5,
        ],
        attachedDatabase: database,
      ),
      alias: null);
  late final Shape1 favorites = Shape1(
      source: i0.VersionedTable(
        entityName: 'favorites',
        withoutRowId: false,
        isStrict: false,
        tableConstraints: [],
        columns: [
          _column_0,
          _column_6,
          _column_7,
        ],
        attachedDatabase: database,
      ),
      alias: null);
  late final Shape2 localSubscriptions = Shape2(
      source: i0.VersionedTable(
        entityName: 'local_subscriptions',
        withoutRowId: false,
        isStrict: false,
        tableConstraints: [],
        columns: [
          _column_0,
          _column_8,
          _column_9,
          _column_10,
          _column_11,
        ],
        attachedDatabase: database,
      ),
      alias: null);
  late final Shape3 userLabels = Shape3(
      source: i0.VersionedTable(
        entityName: 'user_labels',
        withoutRowId: false,
        isStrict: false,
        tableConstraints: [],
        columns: [
          _column_0,
          _column_12,
          _column_13,
        ],
        attachedDatabase: database,
      ),
      alias: null);
  late final Shape5 drafts = Shape5(
      source: i0.VersionedTable(
        entityName: 'drafts',
        withoutRowId: false,
        isStrict: false,
        tableConstraints: [],
        columns: [
          _column_0,
          _column_14,
          _column_15,
          _column_16,
          _column_17,
          _column_18,
          _column_20,
          _column_19,
        ],
        attachedDatabase: database,
      ),
      alias: null);
}

class Shape5 extends i0.VersionedTable {
  Shape5({required super.source, required super.alias}) : super.aliased();
  i1.GeneratedColumn<int> get id => columnsByName['id']! as i1.GeneratedColumn<int>;
  i1.GeneratedColumn<String> get draftType => columnsByName['draft_type']! as i1.GeneratedColumn<String>;
  i1.GeneratedColumn<int> get existingId => columnsByName['existing_id']! as i1.GeneratedColumn<int>;
  i1.GeneratedColumn<int> get replyId => columnsByName['reply_id']! as i1.GeneratedColumn<int>;
  i1.GeneratedColumn<String> get title => columnsByName['title']! as i1.GeneratedColumn<String>;
  i1.GeneratedColumn<String> get url => columnsByName['url']! as i1.GeneratedColumn<String>;
  i1.GeneratedColumn<String> get customThumbnail => columnsByName['custom_thumbnail']! as i1.GeneratedColumn<String>;
  i1.GeneratedColumn<String> get body => columnsByName['body']! as i1.GeneratedColumn<String>;
}

i1.GeneratedColumn<String> _column_20(String aliasedName) => i1.GeneratedColumn<String>('custom_thumbnail', aliasedName, true, type: i1.DriftSqlType.string);

final class Schema5 extends i0.VersionedSchema {
  Schema5({required super.database}) : super(version: 5);
  @override
  late final List<i1.DatabaseSchemaEntity> entities = [
    accounts,
    favorites,
    localSubscriptions,
    userLabels,
    drafts,
  ];
  late final Shape6 accounts = Shape6(
      source: i0.VersionedTable(
        entityName: 'accounts',
        withoutRowId: false,
        isStrict: false,
        tableConstraints: [],
        columns: [
          _column_0,
          _column_1,
          _column_2,
          _column_3,
          _column_4,
          _column_5,
          _column_21,
        ],
        attachedDatabase: database,
      ),
      alias: null);
  late final Shape1 favorites = Shape1(
      source: i0.VersionedTable(
        entityName: 'favorites',
        withoutRowId: false,
        isStrict: false,
        tableConstraints: [],
        columns: [
          _column_0,
          _column_6,
          _column_7,
        ],
        attachedDatabase: database,
      ),
      alias: null);
  late final Shape2 localSubscriptions = Shape2(
      source: i0.VersionedTable(
        entityName: 'local_subscriptions',
        withoutRowId: false,
        isStrict: false,
        tableConstraints: [],
        columns: [
          _column_0,
          _column_8,
          _column_9,
          _column_10,
          _column_11,
        ],
        attachedDatabase: database,
      ),
      alias: null);
  late final Shape3 userLabels = Shape3(
      source: i0.VersionedTable(
        entityName: 'user_labels',
        withoutRowId: false,
        isStrict: false,
        tableConstraints: [],
        columns: [
          _column_0,
          _column_12,
          _column_13,
        ],
        attachedDatabase: database,
      ),
      alias: null);
  late final Shape5 drafts = Shape5(
      source: i0.VersionedTable(
        entityName: 'drafts',
        withoutRowId: false,
        isStrict: false,
        tableConstraints: [],
        columns: [
          _column_0,
          _column_14,
          _column_15,
          _column_16,
          _column_17,
          _column_18,
          _column_20,
          _column_19,
        ],
        attachedDatabase: database,
      ),
      alias: null);
}

class Shape6 extends i0.VersionedTable {
  Shape6({required super.source, required super.alias}) : super.aliased();
  i1.GeneratedColumn<int> get id => columnsByName['id']! as i1.GeneratedColumn<int>;
  i1.GeneratedColumn<String> get username => columnsByName['username']! as i1.GeneratedColumn<String>;
  i1.GeneratedColumn<String> get jwt => columnsByName['jwt']! as i1.GeneratedColumn<String>;
  i1.GeneratedColumn<String> get instance => columnsByName['instance']! as i1.GeneratedColumn<String>;
  i1.GeneratedColumn<bool> get anonymous => columnsByName['anonymous']! as i1.GeneratedColumn<bool>;
  i1.GeneratedColumn<int> get userId => columnsByName['user_id']! as i1.GeneratedColumn<int>;
  i1.GeneratedColumn<int> get listIndex => columnsByName['list_index']! as i1.GeneratedColumn<int>;
}

i1.GeneratedColumn<int> _column_21(String aliasedName) => i1.GeneratedColumn<int>('list_index', aliasedName, false, type: i1.DriftSqlType.int, defaultValue: const Constant(-1));
i0.MigrationStepWithVersion migrationSteps({
  required Future<void> Function(i1.Migrator m, Schema2 schema) from1To2,
  required Future<void> Function(i1.Migrator m, Schema3 schema) from2To3,
  required Future<void> Function(i1.Migrator m, Schema4 schema) from3To4,
  required Future<void> Function(i1.Migrator m, Schema5 schema) from4To5,
}) {
  return (currentVersion, database) async {
    switch (currentVersion) {
      case 1:
        final schema = Schema2(database: database);
        final migrator = i1.Migrator(database, schema);
        await from1To2(migrator, schema);
        return 2;
      case 2:
        final schema = Schema3(database: database);
        final migrator = i1.Migrator(database, schema);
        await from2To3(migrator, schema);
        return 3;
      case 3:
        final schema = Schema4(database: database);
        final migrator = i1.Migrator(database, schema);
        await from3To4(migrator, schema);
        return 4;
      case 4:
        final schema = Schema5(database: database);
        final migrator = i1.Migrator(database, schema);
        await from4To5(migrator, schema);
        return 5;
      default:
        throw ArgumentError.value('Unknown migration from $currentVersion');
    }
  };
}

i1.OnUpgrade stepByStep({
  required Future<void> Function(i1.Migrator m, Schema2 schema) from1To2,
  required Future<void> Function(i1.Migrator m, Schema3 schema) from2To3,
  required Future<void> Function(i1.Migrator m, Schema4 schema) from3To4,
  required Future<void> Function(i1.Migrator m, Schema5 schema) from4To5,
}) =>
    i0.VersionedSchema.stepByStepHelper(
        step: migrationSteps(
      from1To2: from1To2,
      from2To3: from2To3,
      from3To4: from3To4,
      from4To5: from4To5,
    ));