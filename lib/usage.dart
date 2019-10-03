// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shower_thought/home.dart';

import 'auth-page.dart';
import 'register.dart';

class WaterUsageScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        Container(
            height: 750,
            color: Colors.white,
            child: StreamBuilder<QuerySnapshot>(
              stream: Firestore.instance.collection('me').snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError)
                  return new Text('Error: ${snapshot.error}');
                switch (snapshot.connectionState) {
                  case ConnectionState.waiting:
                    return new Text('Loading...');
                  default:
                    List<DocumentSnapshot> documents = snapshot.data.documents;

                    return ListView(
                        children: documents.map((DocumentSnapshot document) {
                      document.data.remove('limit');
                      return new TimeSeriesBar(document.data.entries
                          .map((dataItem) => new TimeSeriesWater(
                              DateTime.parse(dataItem.key),
                              dataItem.value.round().toString()))
                          .toList());
                    }).toList());
                }
              },
            ))
      ],
    );
  }
}
