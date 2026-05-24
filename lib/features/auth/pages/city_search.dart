import 'package:child_tracker/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CitySearchScreen extends StatefulWidget {
  final Function (String city) onSelected;
  const CitySearchScreen({super.key, required this.onSelected});

  @override
  State<CitySearchScreen> createState() => _CitySearchScreenState();
}

class _CitySearchScreenState extends State<CitySearchScreen> {
  String query = '';
  final TextEditingController _searchController = TextEditingController();
  List<String> cities = [
    "Москва",
    "Санкт-Петербург",
    "Новосибирск",
    "Екатеринбург",
    "Нижний Новгород",
    "Казань",
    "Челябинск",
    "Омск",
    "Самара",
    "Ростов-на-Дону",
  ];

  List<String> searchResults = [];

  void onChange(String? val) {
    if (val == null || val.isEmpty) {
      setState(() {
        searchResults = [];
      });
      return;
    } else {
      setState(() {
        query = val;
        searchResults = cities.where((city) => city.toLowerCase().contains(query.toLowerCase())).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        toolbarHeight: 100,
        leadingWidth: 50,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: IconButton(
            icon: const Icon(CupertinoIcons.arrow_left),
            onPressed: () => context.pop(),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: TextFormField(
            onChanged: onChange,
            controller: _searchController,
            textInputAction: TextInputAction.search,
            style: const TextStyle(fontSize: 18, color: greyscale900, fontWeight: FontWeight.w600, fontFamily: Involve),
            maxLength: 60,
            autofocus: true,
            decoration: InputDecoration(
              enabled: true,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              filled: true,
              fillColor: greyscale50,
              hoverColor: primary900.withOpacity(0.08),
              hintText: 'Москва',
              errorMaxLines: 4,
              errorStyle:
                  const TextStyle(fontSize: 16, color: error, fontWeight: FontWeight.normal, fontFamily: Involve),
              hintStyle: const TextStyle(
                  fontSize: 18, color: greyscale500, fontWeight: FontWeight.normal, fontFamily: Involve),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(width: 2, color: primary900),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(width: 2, color: error),
              ),
              counterText: '',
              suffixIconConstraints: const BoxConstraints(
                maxHeight: 40,
                maxWidth: 40,
              ),
              suffix: GestureDetector(
                onTap: () {
                  setState(() {
                    query = '';
                    _searchController.clear();
                  });
                },
                child: const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: SizedBox(width: 20, height: 20, child: Icon(Icons.clear, size: 20)),
                ),
              ),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        itemCount: searchResults.length,
        itemBuilder: (context, index) {
          final city = searchResults[index];
          return GestureDetector(
            onTap: () {
              // context.read<FillDataCubit>().onChangeCity(city);
              widget.onSelected(city);
              context.pop();
            },
            child: Container(
              height: 86,
              width: double.infinity,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: greyscale100)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppText(
                    text: city,
                    size: 20,
                    fw: FontWeight.w700,
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
