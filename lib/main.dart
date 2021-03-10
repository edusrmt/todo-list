import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(title: "Lista de Tarefas", home: Home()));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List _todoList = [];
  Map<String, dynamic> _lastRemoved = Map();
  int _lastRemovedPos;

  @override
  void initState() {
    super.initState();
    _readData().then((data) {
      setState(() {
        _todoList = json.decode(data);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: MyFloatingActionButton(),
      body: Column(
        children: <Widget>[
          Padding(
              padding: EdgeInsets.only(top: 100),
              child: Column(
                children: <Widget>[
                  Padding(
                      padding:
                          EdgeInsets.only(top: 5.0, left: 50.0, right: 20.0),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Flexible(
                              fit: FlexFit.loose,
                              child: Text(
                                "Minhas Tarefas",
                                softWrap: true,
                                overflow: TextOverflow.fade,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 30,
                                    color: Colors.black,
                                    decoration: TextDecoration.none),
                              ),
                            )
                          ])),
                  Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          flex: 2,
                          child: Container(
                            margin: EdgeInsets.only(left: 50),
                            color: Colors.grey,
                            height: 1.5,
                          ),
                        )
                      ],
                    ),
                  )
                ],
              )),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                  padding: EdgeInsets.only(top: 10.0),
                  itemCount: _todoList.length,
                  itemBuilder: buildItem),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildItem(context, index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
          color: Colors.red,
          child: Padding(
            padding: EdgeInsets.only(right: 10),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              Padding(
                  padding: EdgeInsets.only(right: 5),
                  child: Text(
                    "Apagar",
                    style: TextStyle(color: Colors.white),
                  )),
              Icon(
                Icons.delete,
                color: Colors.white,
              )
            ]),
          )),
      direction: DismissDirection.endToStart,
      child: CheckboxListTile(
        controlAffinity: ListTileControlAffinity.leading,
        tileColor:
            _todoList[index]["ok"] ? Color(0xFFF0F0F0) : Color(0xFFFCFCFC),
        title: Text(_todoList[index]["title"],
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: _todoList[index]["ok"]
                ? TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: Colors.black,
                    fontSize: 22.0,
                  )
                : TextStyle(color: Colors.black, fontSize: 22)),
        value: _todoList[index]["ok"],
        onChanged: (c) {
          checkTodo(index, c);
        },
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_todoList[index]);
          _lastRemovedPos = index;
          _todoList.removeAt(index);
          _saveData();

          final snack = SnackBar(
            content: Text("Tarefa ${_lastRemoved["title"]} removida."),
            action: SnackBarAction(
                label: "Desfazer",
                onPressed: () {
                  setState(() {
                    _todoList.insert(_lastRemovedPos, _lastRemoved);
                    _saveData();
                  });
                }),
            duration: Duration(seconds: 2),
          );
          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_todoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }

  void addTodo(String title) {
    setState(() {
      Map<String, dynamic> newTodo = Map();
      newTodo["title"] = title;
      newTodo["ok"] = false;
      _todoList.add(newTodo);
      _saveData();
    });
  }

  void checkTodo(index, c) {
    setState(() {
      _todoList[index]["ok"] = c;
      _saveData();
    });
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _todoList.sort((a, b) {
        if (a["ok"] && !b["ok"])
          return 1;
        else if (!a["ok"] && b["ok"])
          return -1;
        else
          return 0;
      });

      _saveData();
    });

    return null;
  }
}

class MyFloatingActionButton extends StatefulWidget {
  @override
  _MyFloatingActionButtonState createState() => _MyFloatingActionButtonState();
}

class _MyFloatingActionButtonState extends State<MyFloatingActionButton> {
  bool showFab = true;

  @override
  Widget build(BuildContext context) {
    return showFab
        ? FloatingActionButton(
            child: Icon(Icons.add),
            onPressed: () {
              var bottomSheetController = showBottomSheet(
                  context: context, builder: (context) => BottomSheetWidget());
              showFoatingActionButton(false);
              bottomSheetController.closed.then((value) {
                showFoatingActionButton(true);
              });
            },
          )
        : Container();
  }

  void showFoatingActionButton(bool value) {
    setState(() {
      showFab = value;
    });
  }
}

class BottomSheetWidget extends StatefulWidget {
  @override
  _BottomSheetWidgetState createState() => _BottomSheetWidgetState();
}

class _BottomSheetWidgetState extends State<BottomSheetWidget> {
  bool addingTask = false;
  bool success = false;

  TextEditingController _todoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 5, left: 15, right: 15),
      height: 160,
      child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 125,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                  boxShadow: [
                    BoxShadow(
                        blurRadius: 10,
                        color: Colors.grey[300],
                        spreadRadius: 5)
                  ]),
              child: Column(children: <Widget>[
                Container(
                    height: 50,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    margin: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10)),
                    child: TextField(
                      controller: _todoController,
                      decoration: InputDecoration.collapsed(
                        hintText: "Nova tarefa",
                      ),
                    )),
                !addingTask
                    ? MaterialButton(
                        color: Colors.grey[800],
                        onPressed: () async {
                          setState(() {
                            addingTask = true;
                          });

                          await Future.delayed(Duration(milliseconds: 500));

                          context
                              .findAncestorStateOfType<_HomeState>()
                              .addTodo(_todoController.text);
                          _todoController.text = "";

                          setState(() {
                            success = true;
                          });

                          await Future.delayed(Duration(milliseconds: 500));
                          Navigator.pop(context);
                        },
                        child: Text(
                          "Adicionar",
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : !success
                        ? CircularProgressIndicator()
                        : Icon(
                            Icons.check,
                            color: Colors.green,
                          ),
              ]),
            )
          ]),
    );
  }
}
