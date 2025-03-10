import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:open_tv/backend/settings_service.dart';
import 'package:open_tv/backend/sql.dart';
import 'package:open_tv/backend/utils.dart';
import 'package:open_tv/bottom_nav.dart';
import 'package:open_tv/home.dart';
import 'package:open_tv/loading.dart';
import 'package:open_tv/models/settings.dart';
import 'package:open_tv/models/source.dart';
import 'package:open_tv/models/source_type.dart';
import 'package:open_tv/models/view_type.dart';
import 'package:open_tv/error.dart';
import 'package:open_tv/setup.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsState();
}

class _SettingsState extends State<SettingsView> {
  Settings settings = Settings();
  List<Source> sources = [];
  final _formKey = GlobalKey<FormBuilderState>();
  bool loading = true;
  @override
  void initState() {
    super.initState();
    initAsync();
  }

  initAsync() async {
    var results =
        await Future.wait([SettingsService.getSettings(), Sql.getSources()]);
    setState(() {
      settings = results[0] as Settings;
      sources = results[1] as List<Source>;
      loading = false;
    });
  }

  updateView(ViewType view) {
    if (view != ViewType.settings) {
      Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => Home(
              settings: Settings(
                  defaultView: view,
                  refreshOnStart: false,
                  showLivestreams: settings.showLivestreams,
                  showMovies: settings.showMovies,
                  showSeries: settings.showSeries),
            ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) => child,
          ));
    }
  }

  Widget getDefaultViewDialogItem(ViewType view) {
    return ListTile(
      title: Text(viewTypeToString(view)),
      onTap: () {
        setState(() {
          settings.defaultView = view;
          updateSettings();
        });
        Navigator.of(context).pop();
      },
    );
  }

  showEditDialog(BuildContext context, final Source source) async {
    await showDialog(
        context: context,
        builder: (builder) => Center(
                child: SingleChildScrollView(
                    child: AlertDialog(
              title: Text("Edit source ${source.name}"),
              actions: [
                TextButton(
                    onPressed: () async {
                      if (!_formKey.currentState!.saveAndValidate()) {
                        return;
                      }
                      Navigator.of(context).pop();
                      await Error.tryAsyncNoLoading(
                          () async => await Sql.updateSource(Source(
                              id: source.id,
                              name: source.name,
                              sourceType: source.sourceType,
                              url: _formKey.currentState?.value["url"],
                              username: source.sourceType == SourceType.xtream
                                  ? _formKey.currentState?.value["username"]
                                  : null,
                              password: source.sourceType == SourceType.xtream
                                  ? _formKey.currentState?.value["password"]
                                  : null)),
                          context);
                      await reloadSources();
                    },
                    child: const Text("Save")),
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Cancel"))
              ],
              content: FormBuilder(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 15),
                      FormBuilderTextField(
                        initialValue: source.url,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: FormBuilderValidators.compose(
                            [FormBuilderValidators.required()]),
                        decoration: const InputDecoration(
                          labelText: 'Url',
                          prefixIcon: Icon(Icons.link),
                          border: OutlineInputBorder(),
                        ),
                        name: 'url',
                      ),
                      Visibility(
                          visible: source.sourceType == SourceType.xtream,
                          child: const SizedBox(height: 30)),
                      Visibility(
                          visible: source.sourceType == SourceType.xtream,
                          child: FormBuilderTextField(
                            initialValue: source.username,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: FormBuilderValidators.compose(
                                [FormBuilderValidators.required()]),
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              prefixIcon: Icon(Icons.account_circle),
                              border: OutlineInputBorder(),
                            ),
                            name: 'username',
                          )),
                      Visibility(
                          visible: source.sourceType == SourceType.xtream,
                          child: const SizedBox(height: 30)),
                      Visibility(
                          visible: source.sourceType == SourceType.xtream,
                          child: FormBuilderTextField(
                            initialValue: source.password,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: FormBuilderValidators.compose(
                                [FormBuilderValidators.required()]),
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.password),
                              border: OutlineInputBorder(),
                            ),
                            name: 'password',
                          )),
                    ],
                  )),
            ))));
  }

  _showDefaultViewDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Default view"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children:
                ViewType.values.take(4).map(getDefaultViewDialogItem).toList(),
          ),
        );
      },
    );
  }

  toggleSource(Source source) async {
    await Error.tryAsyncNoLoading(
        () async => await Sql.setSourceEnabled(!source.enabled, source.id!),
        context);
    await reloadSources();
  }

  Widget getSource(Source source) {
    return Card(
        margin: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 5), // Spacing around the tile
        elevation: 5,
        color: source.enabled
            ? Theme.of(context).colorScheme.surfaceContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        child: ListTile(
          onLongPress: () => toggleSource(source),
          contentPadding: const EdgeInsets.only(left: 20),
          title: Text(source.name),
          subtitle: Text(getSourceTypeString(source.sourceType)),
          trailing: Row(
            mainAxisSize:
                MainAxisSize.min, // Ensures the row takes up minimal space
            children: [
              Offstage(
                  offstage: source.sourceType == SourceType.m3u,
                  child: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () async {
                      await Error.tryAsync(() async {
                        await Utils.refreshSource(source);
                      }, context, "Source has been refreshed successfully");
                    },
                  )),
              Offstage(
                  offstage: source.sourceType == SourceType.m3u,
                  child: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async =>
                        await showEditDialog(context, source),
                  )),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async => await showConfirmDeleteDialog(source),
              ),
            ],
          ),
        ));
  }

  showConfirmDeleteDialog(Source source) async {
    await showDialog(
        context: context,
        builder: (builder) => AlertDialog(
              title: const Text("Confirm deletion"),
              content: Text.rich(TextSpan(children: [
                const TextSpan(text: "You are about to delete source "),
                TextSpan(
                    text: source.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const TextSpan(text: ", are you sure?"),
              ])),
              actions: [
                TextButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await Error.tryAsync(
                          () async => await Sql.deleteSource(source.id!),
                          context,
                          "Successfully deleted source");
                      await reloadSources();
                      if (sources.isEmpty) {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const Setup()));
                      }
                    },
                    child: const Text("Confirm")),
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Cancel"))
              ],
            ));
  }

  reloadSources() async {
    await Error.tryAsyncNoLoading(
        () async => sources = await Sql.getSources(), context);
    setState(() {
      sources;
    });
  }

  updateSettings() async {
    await Error.tryAsyncNoLoading(
        () async => await SettingsService.updateSettings(settings), context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Visibility(
          visible: !loading,
          child: Loading(
              child: SafeArea(
                  child: Padding(
                      padding:
                          const EdgeInsetsDirectional.symmetric(vertical: 10),
                      child: ListView(
                        children: [
                          const SizedBox(height: 10),
                          const Padding(
                              padding: EdgeInsets.only(left: 10),
                              child: Text('Settings',
                                  style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold))),
                          const SizedBox(height: 10),
                          ListTile(
                              title: const Text("Donate"),
                              subtitle: const Text(
                                  "Open TV needs your help! Consider donating ❤️"),
                              onTap: () async => await launchUrl(
                                  Uri.parse(
                                    "https://github.com/Fredolx/open-tv-mobile/discussions/1",
                                  ),
                                  mode: LaunchMode.externalApplication)),
                          ListTile(
                              title: const Text("Default view"),
                              subtitle:
                                  Text(viewTypeToString(settings.defaultView)),
                              onTap: () async =>
                                  await _showDefaultViewDialog(context)),
                          ListTile(
                            title: const Text("Refresh sources on start"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Switch(
                                  value: settings.refreshOnStart,
                                  onChanged: (bool value) {
                                    setState(() {
                                      settings.refreshOnStart = value;
                                    });
                                    updateSettings();
                                  },
                                ),
                              ],
                            ),
                          ),
                          ListTile(
                            title: const Text("Show livestreams"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Switch(
                                  value: settings.showLivestreams,
                                  onChanged: (bool value) {
                                    setState(() {
                                      settings.showLivestreams = value;
                                    });
                                    updateSettings();
                                  },
                                ),
                              ],
                            ),
                          ),
                          ListTile(
                            title: const Text("Show movies"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Switch(
                                  value: settings.showMovies,
                                  onChanged: (bool value) {
                                    setState(() {
                                      settings.showMovies = value;
                                    });
                                    updateSettings();
                                  },
                                ),
                              ],
                            ),
                          ),
                          ListTile(
                            title: const Text("Show series"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Switch(
                                  value: settings.showSeries,
                                  onChanged: (bool value) {
                                    setState(() {
                                      settings.showSeries = value;
                                    });
                                    updateSettings();
                                  },
                                ),
                              ],
                            ),
                          ),
                          const Divider(),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Padding(
                                    padding: EdgeInsets.only(left: 10),
                                    child: Text('Sources',
                                        style: TextStyle(
                                            fontSize: 30,
                                            fontWeight: FontWeight.bold))),
                                Row(children: [
                                  IconButton(
                                      onPressed: () async => await Error.tryAsync(
                                          () async =>
                                              await Utils.refreshAllSources(),
                                          context,
                                          "Successfully refreshed all sources"),
                                      icon: const Icon(Icons.refresh)),
                                  IconButton(
                                      onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => const Setup(
                                                    showAppBar: true,
                                                  ))),
                                      icon: const Icon(Icons.add))
                                ])
                              ]),
                          const SizedBox(height: 10),
                          ...sources.map(getSource)
                        ],
                      ))))),
      bottomNavigationBar: BottomNav(
        updateViewMode: updateView,
        startingView: ViewType.settings,
      ),
    );
  }
}
