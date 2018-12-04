import 'package:flutter/material.dart';
import 'package:outline_material_icons/outline_material_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xkcd/api/comic_api_client.dart';
import 'package:xkcd/data/comic.dart';
import 'package:xkcd/utils/app_localizations.dart';
import 'package:xkcd/utils/constants.dart';
import 'package:xkcd/utils/preferences.dart';
import 'package:xkcd/widgets/comic_view.dart';

class FavoritesPage extends StatefulWidget {
  static final String pageRoute = '/favorites-page';

  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final SharedPreferences prefs = Preferences.prefs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).get('favorites')),
        elevation: 0.0,
      ),
      body: Padding(
        padding: EdgeInsets.all(4.0),
        child: _buildFavoritesList(),
      ),
    );
  }

  Widget _buildFavoritesList() {
    final favorites = prefs.getStringList(Constants.favorites);
    if (favorites != null && favorites.isNotEmpty) {
      return FutureBuilder(
        future: ComicApiClient.fetchComics(favorites),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
              return Center(child: CircularProgressIndicator());
            default:
              if (snapshot.hasError) {
                debugPrint(snapshot.toString());
                return Container(width: 0.0, height: 0.0);
              } else {
                var data = snapshot.data;
                if (data != null && data is List) {
                  return ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      Comic comic = data[index];
                      return _buildListTile(index, context, comic);
                    },
                  );
                }
              }
          }
        },
      );
    }
    return Center(
      child: Text(AppLocalizations.of(context).get('nothing_here')),
    );
  }

  Widget _buildListTile(int index, BuildContext context, Comic comic) {
    return ListTile(
      contentPadding: EdgeInsets.all(12.0),
      leading: Hero(
        tag: 'hero-${comic.num}',
        child: Image.network(
          comic.img,
          width: 50.0,
          height: 60.0,
        ),
      ),
      title: Text('${comic.num}: ${comic.title}'),
      trailing: IconButton(
        icon: Icon(OMIcons.delete),
        padding: EdgeInsets.all(0.0),
        alignment: Alignment.centerRight,
        onPressed: () {
          setState(() {
            _removeFavorite(context, comic);
          });
        },
      ),
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          maintainState: true,
          builder: (context) {
            return ComicView(comic);
          },
        ));
      },
    );
  }

  void _removeFavorite(BuildContext context, Comic comic) {
    var num = comic.num.toString();
    List<String> favorites = prefs.getStringList(Constants.favorites);
    if (favorites == null || favorites.isEmpty) {
      return;
    }
    if (favorites.contains(num)) {
      favorites.remove(num);
    }
    prefs.setStringList(Constants.favorites, favorites);

    Scaffold.of(context).showSnackBar(
      SnackBar(
        content: Text.rich(TextSpan(children: [
          TextSpan(
            text: '${comic.title}',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: ' ${AppLocalizations.of(context).get('favorite_removed')}'),
        ])),
      ),
    );
  }
}
