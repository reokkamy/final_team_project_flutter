// lib/screens/result_page.dart
import 'package:flutter/material.dart';
import 'restaurant_map_screen.dart'; // 지도 화면 import

class ResultPage extends StatelessWidget {
  final Map<String, dynamic> food;
  final VoidCallback onBack;

  const ResultPage({
    super.key,
    required this.food,
    required this.onBack,
  });

  // 영양소 값 가져오기 헬퍼 함수
  static String? _getNutritionValue(Map<String, dynamic> food, String key) {
    if (food['nutrition'] == null) return null;
    final nutrition = food['nutrition'] as Map<String, dynamic>;
    final value = nutrition[key];
    if (value == null) return null;
    
    // double 또는 int를 문자열로 변환
    if (value is double) {
      return '${value.toStringAsFixed(1)}g';
    } else if (value is int) {
      return '${value}g';
    } else if (value is num) {
      return '${value.toStringAsFixed(1)}g';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final similarFoods = ['비프 스파게티', '알리오 올리오', '까르보나라 파스타'];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF1a3344),
                          Color(0xFF0d1a22),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        '🍝',
                        style: TextStyle(fontSize: 80),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.9),
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.black),
                            onPressed: onBack,
                          ),
                        ),
                        CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.9),
                          child: IconButton(
                            icon: const Icon(Icons.more_vert, color: Colors.black),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '📅 오늘, 3:09 오후',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            '❤️ 건강도: ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            food['accuracy'] != null
                                ? '${food['accuracy'].toStringAsFixed(0)}%'
                                : '${food['rating']} / 10',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Text(
                            food['name'] ?? '알 수 없음',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                          ),
                          if (food['message'] != null && food['message'].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                food['message'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            '칼로리 & 매크로',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _MacroCard(
                                  label: '칼로리',
                                  value: food['calories'] != null && food['calories'] > 0
                                      ? '${food['calories']} kcal'
                                      : food['nutrition'] != null && food['nutrition']['calories'] != null
                                          ? '${food['nutrition']['calories'].toStringAsFixed(0)} kcal'
                                          : '-',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _MacroCard(
                                  label: '정확도',
                                  value: food['accuracy'] != null
                                      ? '${food['accuracy'].toStringAsFixed(0)}%'
                                      : '-',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _MacroCardSmall(
                                  label: '탄수화물',
                                  icon: '🌾',
                                  value: _getNutritionValue(food, 'carbohydrates'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _MacroCardSmall(
                                  label: '단백질',
                                  icon: '🥩',
                                  value: _getNutritionValue(food, 'protein'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _MacroCardSmall(
                                  label: '지방',
                                  icon: '🥑',
                                  value: _getNutritionValue(food, 'fat'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border(
                          left: BorderSide(
                            color: Colors.blue,
                            width: 4,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text('ℹ️', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '해물 파스타(토마토소스) 아닌가요?',
                              style: TextStyle(
                                color: Colors.blue[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 💡 새로 추가된 "내 주변 찾기" 버튼
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // 지도 화면으로 이동하면서 음식 이름 전달
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RestaurantMapScreen(
                                foodName: food['name'], // 분석된 음식 이름 전달
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.location_on),
                        label: const Text(
                          '내 주변 가게 찾기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1a3344),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 기존 "검색하기" 버튼
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          '검색하기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...similarFoods.map((foodName) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(
                          foodName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                        ),
                        onTap: () {},
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MacroCard extends StatelessWidget {
  final String label;
  final String value;

  const _MacroCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroCardSmall extends StatelessWidget {
  final String label;
  final String icon;
  final String? value;

  const _MacroCardSmall({
    required this.label,
    required this.icon,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          value != null
              ? Text(
                  value!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 4),
              Text(
                '🔒',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}