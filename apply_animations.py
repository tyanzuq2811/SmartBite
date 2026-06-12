import sys

file_path = r'c:\Users\nguye\Documents\mobile\duan\lib\presentation\home\home_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    code = f.read()

# Thêm import
if 'flutter_staggered_animations' not in code:
    code = code.replace("import 'package:animations/animations.dart';", "import 'package:animations/animations.dart';\nimport 'package:flutter_staggered_animations/flutter_staggered_animations.dart';")

# Bọc ListView dọc
old_listview_vert = """                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  children: ["""

new_listview_vert = """                child: AnimationLimiter(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    children: AnimationConfiguration.toStaggeredList(
                      duration: const Duration(milliseconds: 400),
                      childAnimationBuilder: (widget) => SlideAnimation(
                        verticalOffset: 40.0,
                        curve: Curves.easeOutCubic,
                        child: FadeInAnimation(child: widget),
                      ),
                      children: ["""
code = code.replace(old_listview_vert, new_listview_vert)

# Đóng block của ListView dọc
old_listview_vert_end = """                    const SizedBox(height: 80), // Padding to avoid overlap with bottom bar & FAB
                  ],
                ),"""
new_listview_vert_end = """                    const SizedBox(height: 80), // Padding to avoid overlap with bottom bar & FAB
                      ],
                    ),
                  ),
                ),"""
code = code.replace(old_listview_vert_end, new_listview_vert_end)

# Bọc ListView.builder ngang
old_listview_horiz = """                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,"""

new_listview_horiz = """                    SizedBox(
                      height: 220,
                      child: AnimationLimiter(
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,"""
code = code.replace(old_listview_horiz, new_listview_horiz)

old_listview_horiz_item = """                          final isFirst = index == 0;
                          
                           return Container("""

new_listview_horiz_item = """                          final isFirst = index == 0;
                          
                           return AnimationConfiguration.staggeredList(
                             position: index,
                             duration: const Duration(milliseconds: 500),
                             child: SlideAnimation(
                               horizontalOffset: 50.0,
                               curve: Curves.easeOutCubic,
                               child: FadeInAnimation(
                                 child: Container("""
code = code.replace(old_listview_horiz_item, new_listview_horiz_item)

old_listview_horiz_end = """                                     ),
                                   ),
                                 );
                               },
                             ),
                           );
                        },
                      ),
                    ),"""
new_listview_horiz_end = """                                     ),
                                   ),
                                 );
                               },
                             ),
                                 ),
                               ),
                             ),
                           );
                        },
                      ),
                      ),
                    ),"""
code = code.replace(old_listview_horiz_end, new_listview_horiz_end)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(code)
print("Updated home_screen.dart")
