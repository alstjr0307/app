import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'allDetail.dart';
import 'package:flutter_app/Navigatior/postTab.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'addPost.dart';
class AllPost extends StatefulWidget {
  @override
  _AllPostState createState() => _AllPostState();
}

class _AllPostState extends State<AllPost>
    with AutomaticKeepAliveClientMixin<AllPost> {

  ScrollController _sc = new ScrollController();

  static int page = 0;
  bool isLoading = false;
  List posts = [];
  final dio = new Dio();
  int maxpage;
  var posttype = '';

  @override
  void initState() {
    _getMoreData(page);
    super.initState();
    _sc.addListener(() {
      if (_sc.position.pixels == _sc.position.maxScrollExtent &&
          page < maxpage) {
        _getMoreData(page);
      }
    });
    print('이닛');
  }

  @override
  void dispose() {
    _sc.dispose();
    page = 0;
    posts = [];
    isLoading = false;

    super.dispose();
  }

  void _getMoreData(int index) async {
    //데이터 추가하기
    List tList = [];

    var sharedPreferences = await SharedPreferences.getInstance();
    var token = sharedPreferences.getString("token"); //token 값 불러오기

    if (!isLoading) {
      setState(() {
        isLoading = true;
      });

      var url = "http://13.125.62.90/api/v1/BlogPosts/?page=" +
          (index + 1).toString();
      print(url);
      final response = await dio.get(url,
          options: Options(headers: {"Authorization": "Token ${token}"}));
      maxpage = (response.data['count'] - 1) ~/ 10 + 1;
      print('맥페${maxpage}');
      tList = [];

      for (int i = 0; i < response.data['results'].length; i++) {
        tList.add(response.data['results'][i]);
        if (response.data['results'][i]['category'] == 'D')
          tList[i]['type'] = '국내';
        else if (response.data['results'][i]['category'] == 'F')
          tList[i]['type'] = '해외';
        else if (response.data['results'][i]['category'] == 'R')
          tList[i]['type'] = '자유';
        tList[i]['time'] = DateFormat("M월dd일 H:m").format(DateTime.parse(tList[i]['create_dt']));
      }


      setState(() {
        isLoading = false;
        posts.addAll(tList);
        page++;
      });
      print('페이지${page}');
    }
  }

  Future<void> _getData() async {
    //새로고침을 위한 것
    setState(() {
      page = 0;
      posts = [];
      _getMoreData(page);
    });
  }

  Widget _buildList() {
    return Container(
      child: RefreshIndicator(
        child: ListView.builder(
            itemCount: posts.length + 1,
            controller: _sc,
            // Add one more item for progress indicator
            padding: EdgeInsets.symmetric(vertical: 8.0),
            itemBuilder: (BuildContext context, int index) {
              print('index${index}');
              if (index == posts.length) {
                return _buildProgressIndicator();
              } else {
                return Container(
                  margin: new EdgeInsets.fromLTRB(5, 0, 5, 0),
                  width: 25.0,
                  height: 80.0,
                  child: InkWell(
                    child: Card(
                      margin: EdgeInsets.symmetric(vertical: 2, horizontal: 0),
                      color: Colors.white70,
                      elevation: 5,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(10.0,0,8.0,0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(),
                                  Text(
                                    (posts[index]['title']),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Icon(Icons.person, size:15),
                                            Text(
                                              (posts[index]['writer'].toString()), style: TextStyle(fontSize: 12),
                                            ),
                                            SizedBox(width:10),
                                            Icon(Icons.comment, size: 15, color: Colors.redAccent,),
                                            Text(
                                               ' ${posts[index]['comment'].toString()}', style: TextStyle(fontSize:12,color: Colors.red)),

                                            SizedBox(width:10),
                                            Icon(Icons.thumb_up, size:15, color: Colors.red,),
                                            Text(' ${posts[index]['likes'].toString()}', style: TextStyle(fontSize :12, color: Colors.red))

                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Icon(Icons.timer, size: 12,color: Colors.grey),
                                          Text(posts[index]['time'],style: TextStyle(fontSize: 12, color: Colors.grey)),
                                        ],
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.all(4.0),
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blueAccent,
                              border: Border.all(width: 1.0, color: Colors.white),
                            ),
                            child: Text(posts[index]['type'],
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => allDetail(
                            index: posts[index]["id"],
                          ),
                        ),
                      );
                    },
                  ),
                );
              }
            }),
        onRefresh: _getData,
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return new Padding(
      padding: const EdgeInsets.all(8.0),
      child: new Center(
        child: new Opacity(
          opacity: isLoading ? 1.0 : 00,
          child: new CircularProgressIndicator(),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
  Map user;
  List data;
  Widget screen;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('전체'),
        actions: [
          IconButton(icon: Icon(Icons.add), onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>AddPost()
              )
            );

          })
        ],
      ),

      body: _buildList(),
    );
  }

}
