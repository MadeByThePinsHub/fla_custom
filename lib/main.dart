import 'package:api/api.dart';
import 'package:api/data.dart';
import 'package:api/decoder/forums.dart';
import 'package:appConfig/appConfig.dart';
import 'package:core/LoginPage.dart';
import 'package:core/SplashPage.dart';
import 'package:core/UserPage.dart';
import 'package:core/list/DiscussionsList.dart';
import 'package:core/list/TagsList.dart';
import 'package:core/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:i18n/i18n.dart';
import 'package:i18n/timeAgo.dart';
import 'package:util/SystemUI.dart';
import 'package:util/color.dart';

/// 👇👇👇 Set your website link here, that's it. 👇👇👇

const siteUrl = "https://community.madebythepins.tk";

/// 👆👆👆 Set your website link here, that's it. 👆👆👆

void main() {
  TimeAgo.init();
  runApp(MainPage());
  SystemUI.setStatusBarColor(Colors.transparent, Brightness.light);
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  InitData initData;
  GlobalKey<ScaffoldState> scaffold = GlobalKey();
  bool _isLoading = false;
  int pageIndex = 0;
  String discussionSort = "";
  Color textColor;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          primaryColor:
              initData != null && initData.forumInfo.themePrimaryColor != null
                  ? HexColor.fromHex(initData.forumInfo.themePrimaryColor)
                  : Colors.blue,
          brightness: Brightness.light),
      darkTheme: ThemeData(brightness: Brightness.dark),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        S.delegate
      ],
      supportedLocales: [
        const Locale('en'),
        const Locale('zh', 'CN'),
      ],
      home: Builder(builder: (BuildContext context) {
        textColor =
            ColorUtil.getTitleFormBackGround(Theme.of(context).primaryColor);

        if (initData == null && !_isLoading) {
          initApp(context).then((result) {
            setState(() {
              initData = result;
              _isLoading = false;
            });
          });
        }
        return _isLoading
            ? Scaffold(
                body: Center(
                child: CircularProgressIndicator(),
              ))
            : Scaffold(
                key: scaffold,
                appBar: AppBar(
                  brightness: ColorUtil.getBrightnessFromBackground(
                      Theme.of(context).primaryColor),
                  title: ListTile(
                    title: Text(
                      initData.forumInfo.title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: TextStyle(color: textColor, fontSize: 20),
                    ),
                    subtitle: pageIndex == 0
                        ? makeSortPopupMenu(
                            context,
                            discussionSort,
                            ColorUtil.getSubtitleFormBackGround(
                                Theme.of(context).primaryColor), (key) async {
                            setState(() {
                              discussionSort = key;
                              initData.discussions = null;
                            });
                            initData.discussions =
                                await Api.getDiscussionList(key);
                            if (initData.discussions != null) {
                              setState(() {});
                            }
                          })
                        : null,
                  ),
                  centerTitle: true,
                  leading: IconButton(
                    icon: Icon(Icons.keyboard_arrow_left),
                    onPressed: (){
                      //Navigator.pop(context);
                      SystemChannels.platform.invokeMethod('SystemNavigator.pop');
                    },
                  ),
                  actions: <Widget>[
                    IconButton(icon: Builder(
                      builder: (BuildContext context) {
                        if (Api.isLogin()) {
                          return makeUserAvatarImage(initData.loggedUser,
                              Theme.of(context).primaryColor, 26, 8);
                        }
                        return Icon(
                          Icons.account_circle,
                          color: textColor,
                        );
                      },
                    ), onPressed: () {
                      if (initData.loggedUser != null) {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (BuildContext context) {
                              return UserPage();
                            }));
                      } else {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (BuildContext context) {
                              return LoginPage();
                            })).then((ok) {
                          if (ok != null && ok) {
                            refreshUI();
                          }
                        });
                      }
                    }),
                  ],
                ),
                body: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: IndexedStack(
                    key: Key(pageIndex.toString()),
                    index: pageIndex,
                    children: <Widget>[
                      ListPage(initData, Theme.of(context).primaryColor),
                      TagsPage(initData)
                    ],
                  ),
                ),
                floatingActionButton: FloatingActionButton(
                    tooltip: S.of(context).title_new_post,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: FaIcon(
                      FontAwesomeIcons.pen,
                      color: textColor,
                    ),
                    onPressed: () {}),
                floatingActionButtonLocation:
                    FloatingActionButtonLocation.centerDocked,
                bottomNavigationBar: BottomAppBar(
                  shape: CircularNotchedRectangle(),
                  color: Theme.of(context).primaryColor,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      IconButton(
                        tooltip: S.of(context).title_home,
                        icon: Icon(
                          Icons.home,
                          color: textColor,
                        ),
                        onPressed: () {
                          setState(() {
                            pageIndex = 0;
                          });
                        },
                      ),
                      IconButton(
                          tooltip: S.of(context).title_tags,
                          icon: Icon(
                            Icons.apps,
                            color: textColor,
                          ),
                          onPressed: () {
                            setState(() {
                              pageIndex = 1;
                            });
                          })
                    ],
                  ),
                ),
              );
      }),
    );
  }

  Future<InitData> initApp(BuildContext context) async {
    _isLoading = true;
    await AppConfig.init();
    var sites = await AppConfig.getSiteList();
    ForumInfo info;
    if (sites == null || sites.length == 0) {
      await AppConfig.addSite(SiteInfo("$siteUrl/api", "", "", -1, ""));
      info = await Api.checkUrl("$siteUrl/api");
      if (info == null) {
        print("URL or Internet ERROR!");
        SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      }
      await AppConfig.setSiteIndex(0);
    } else {
      if (sites.length < (await AppConfig.getSiteIndex())) {
        await AppConfig.setSiteIndex(0);
      }
      var site =
          (await AppConfig.getSiteList())[await AppConfig.getSiteIndex()];
      info = await Api.checkUrl(site.url);
    }
    if (info == null) {
      return null;
    }
    var result = await Navigator.push(context,
        MaterialPageRoute(builder: (BuildContext context) {
      return Splash(info);
    }));
    if (result != null || result is InitData) {
      return result;
    }
    return null;
  }

  void refreshUI() {
    setState(() {
      discussionSort = "";
      initData = null;
    });
  }
}
