// lib/screens/restaurant_map_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io'; // Platform 사용을 위해 추가
import '../util/debug_helper.dart';

class RestaurantMapScreen extends StatefulWidget {
  final String foodName;

  const RestaurantMapScreen({Key? key, required this.foodName}) : super(key: key);

  @override
  _RestaurantMapScreenState createState() => _RestaurantMapScreenState();
}

class _RestaurantMapScreenState extends State<RestaurantMapScreen> {
  bool _isLoading = true;
  String _errorMessage = '';

  Position? _currentPosition;
  List<dynamic> _restaurantList = [];
  final Set<Marker> _markers = {};

  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    print('\n========================================');
    print('🍽️ RestaurantMapScreen 시작');
    print('🍽️ 음식 이름: ${widget.foodName}');
    print('========================================\n');
    _checkPermissionAndLoadMap();
  }

  Future<void> _checkPermissionAndLoadMap() async {
    print('🍽️ [1단계] 위치 권한 확인 시작');

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      print('🍽️ 현재 권한: $permission');

      if (permission == LocationPermission.denied) {
        print('🍽️ 권한 요청 중...');
        permission = await Geolocator.requestPermission();
        print('🍽️ 권한 요청 결과: $permission');

        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = '위치 권한이 거부되었습니다.';
            _isLoading = false;
          });
          print('❌ 권한 거부됨');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = '위치 권한이 영구적으로 거부되었습니다.\n설정에서 권한을 허용해주세요.';
          _isLoading = false;
        });
        print('❌ 권한 영구 거부됨');
        return;
      }

      print('✅ 위치 권한 확보 완료');
      await findRestaurantsAndSetMarkers();
    } catch (e) {
      print('❌ 권한 확인 중 에러: $e');
      setState(() {
        _errorMessage = '위치 권한 확인 중 오류: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> findRestaurantsAndSetMarkers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 1. 현재 위치
      print('\n🍽️ [2단계] 현재 위치 가져오기');
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (_currentPosition == null) {
        throw Exception("위치 정보를 가져올 수 없습니다.");
      }

      print('✅ 위도: ${_currentPosition!.latitude}');
      print('✅ 경도: ${_currentPosition!.longitude}');

      // 2. API 호출
      print('\n🍽️ [3단계] 백엔드 API 호출');

      // 서버 URL 설정 (플랫폼별로 다른 URL 사용)
      String baseUrl;
      if (Platform.isAndroid) {
        baseUrl = '10.100.201.6:8080'; // Android 에뮬레이터
      } else if (Platform.isIOS) {
        baseUrl = '192.168.50.80:8080'; // iOS 시뮬레이터 - Mac의 실제 IP 주소
      } else {
        baseUrl = 'localhost:8080'; // 기타 플랫폼
      }
      final String path = '/api/map/search';
      final params = {
        'foodName': widget.foodName,
        'latitude': _currentPosition!.latitude.toString(),
        'longitude': _currentPosition!.longitude.toString(),
      };

      var uri = Uri.http(baseUrl, path, params);

      print('📡 요청 URL: $uri');
      print('📤 요청 파라미터:');
      print('   - foodName: ${widget.foodName}');
      print('   - latitude: ${_currentPosition!.latitude}');
      print('   - longitude: ${_currentPosition!.longitude}');

      final startTime = DateTime.now();
      var response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('서버 연결 시간 초과 (10초).\n서버가 실행 중인지 확인해주세요.');
        },
      );
      final duration = DateTime.now().difference(startTime);

      print('📥 응답 시간: ${duration.inMilliseconds}ms');
      print('📥 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        String responseBody = utf8.decode(response.bodyBytes);
        print('✅ 응답 성공!');
        print('📦 응답 데이터: $responseBody');

        _restaurantList = jsonDecode(responseBody);
        print('✅ JSON 파싱 성공');
        print('🏪 검색된 식당 수: ${_restaurantList.length}');

        // 3. 마커 생성
        print('\n🍽️ [4단계] 지도 마커 생성');
        _markers.clear();

        // 내 위치 마커
        _markers.add(
          Marker(
            markerId: const MarkerId('my_location'),
            position: LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: const InfoWindow(title: '내 위치'),
          ),
        );
        print('📍 내 위치 마커 추가 완료');

        // 식당 마커들
        for (var i = 0; i < _restaurantList.length; i++) {
          var restaurant = _restaurantList[i];
          final lat = restaurant['latitude'];
          final lng = restaurant['longitude'];
          final name = restaurant['name'];
          final address = restaurant['address'];

          if (lat != null && lng != null) {
            _markers.add(
              Marker(
                markerId: MarkerId('restaurant_$i'),
                position: LatLng(lat, lng),
                infoWindow: InfoWindow(
                  title: name ?? '식당',
                  snippet: address ?? '',
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              ),
            );
            print('📍 [$i] 마커 추가: $name (위도: $lat, 경도: $lng)');
          } else {
            print('⚠️ [$i] 위치 정보 없음: $restaurant');
          }
        }

        print('✅ 총 ${_markers.length}개 마커 생성 완료 (내 위치 포함)');

        // 마커 생성 후 카메라를 현재 위치로 이동
        if (_mapController != null && _currentPosition != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
              ),
              14.0, // 적절한 줌 레벨
            ),
          );
          print('✅ 카메라를 현재 위치로 이동 완료');
        }

        print('\n========================================');
        print('✅✅✅ 모든 작업 성공! ✅✅✅');
        print('========================================\n');

        if (_restaurantList.isEmpty) {
          setState(() {
            _errorMessage = '"${widget.foodName}"을(를) 판매하는\n주변 식당을 찾지 못했습니다.';
          });
          print('⚠️ 검색 결과가 없습니다.');
        }
      } else {
        String errorBody = utf8.decode(response.bodyBytes);
        print('❌ 서버 에러 발생!');
        print('❌ 상태 코드: ${response.statusCode}');
        print('❌ 에러 내용: $errorBody');
        throw Exception("서버 에러: ${response.statusCode}\n$errorBody");
      }
    } catch (e, stackTrace) {
      print('\n========================================');
      print('❌❌❌ 에러 발생! ❌❌❌');
      print('========================================');
      print('에러: $e');
      print('스택 트레이스: $stackTrace');
      print('========================================\n');

      // Connection refused 오류에 대한 친절한 메시지 (에러 메시지 업데이트 필요 시 여기 수정)
      String errorMessage = '식당 검색 중 오류가 발생했습니다.';
      if (e.toString().contains('Connection refused') || 
          e.toString().contains('errno = 61')) {
        errorMessage = '백엔드 서버에 연결할 수 없습니다.\n\n'
            '확인 사항:\n'
            '1. 백엔드 서버가 실행 중인지 확인\n'
            '2. 서버가 0.0.0.0:8080에 바인딩되어 있는지 확인\n'
            '3. iOS 시뮬레이터의 경우 Mac IP 주소 사용 중\n'
            '   (현재: http://192.168.50.80:8080)\n\n'
            '지도는 표시되지만 식당 정보는 불러올 수 없습니다.';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = '네트워크 연결 오류가 발생했습니다.\n\n'
            '인터넷 연결과 서버 상태를 확인해주세요.\n\n'
            '지도는 표시되지만 식당 정보는 불러올 수 없습니다.';
      } else {
        errorMessage = '식당 검색 중 오류가 발생했습니다.\n\n'
            '에러: ${e.toString()}\n\n'
            '지도는 표시되지만 식당 정보는 불러올 수 없습니다.';
      }

      setState(() {
        _errorMessage = errorMessage;
        // 서버 연결 실패해도 지도는 표시되도록 _isLoading을 false로 설정
        _isLoading = false;
      });
      
      // 내 위치 마커는 추가 (서버 연결 실패해도)
      if (_currentPosition != null) {
        _markers.clear();
        _markers.add(
          Marker(
            markerId: const MarkerId('my_location'),
            position: LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: const InfoWindow(title: '내 위치'),
          ),
        );
        print('📍 내 위치 마커 추가 완료 (서버 연결 실패)');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("'${widget.foodName}' 주변 가게"),
        backgroundColor: const Color(0xFF1a3344),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              print('\n🔄 새로고침 시작\n');
              findRestaurantsAndSetMarkers();
            },
            tooltip: '다시 검색',
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. 구글맵 (항상 표시)
            GoogleMap(
              initialCameraPosition: CameraPosition(
              target: _currentPosition != null
                  ? LatLng(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                    )
                  : const LatLng(37.5665, 126.9780), // 서울시청 기본 위치
                zoom: 15,
              ),
            // cloudMapId는 선택사항 (Google Cloud Map ID가 있으면 사용)
            // cloudMapId: '9ab22eab75ae97fa799273bf',
              onMapCreated: (controller) {
                _mapController = controller;
                print('✅ Google Map 생성 완료');
                
                // 지도가 완전히 로드된 후 카메라 이동
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_currentPosition != null && mounted) {
                    controller.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                        15.0, // 줌 레벨 명시
                      ),
                    );
                    print('✅ 카메라 이동 완료: 위도 ${_currentPosition!.latitude}, 경도 ${_currentPosition!.longitude}');
                  } else if (_markers.isNotEmpty && mounted) {
                    // 마커가 있으면 첫 번째 마커 위치로 이동
                    final firstMarker = _markers.first;
                    controller.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        firstMarker.position,
                        13.0,
                      ),
                    );
                    print('✅ 카메라 이동 완료: 첫 번째 마커 위치로');
                  }
                });
              },
              markers: _markers,  // 마커는 이미 생성되어 있음
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              mapType: MapType.normal,
              zoomControlsEnabled: true,
              compassEnabled: true,
              mapToolbarEnabled: false,
              // 지도 로드 상태 확인
              onCameraMoveStarted: () {
                print('📷 카메라 이동 시작');
              },
              onCameraIdle: () {
                print('📷 카메라 이동 완료');
              },
            onTap: (LatLng position) {
              print('📍 지도 탭: 위도 ${position.latitude}, 경도 ${position.longitude}');
            },
          ),
          // 2. 로딩 오버레이
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                    Text(
                      "주변 식당을 검색하는 중...",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  SizedBox(height: 8),
                  Text(
                    "콘솔 로그를 확인하세요",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              ),
            ),
          // 3. 에러 오버레이
          if (_errorMessage.isNotEmpty && !_isLoading)
            Container(
              color: Colors.white.withOpacity(0.95),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "오류 발생",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          print('\n🔄 다시 시도 시작\n');
                          _checkPermissionAndLoadMap();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('다시 시도'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1a3344),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  ),
                ),
              ),

          // 4. 하단 정보
          if (!_isLoading && _errorMessage.isEmpty && _restaurantList.isNotEmpty)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.restaurant, color: Color(0xFF1a3344)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '주변에 ${_restaurantList.length}개의 식당을 찾았습니다',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    print('🍽️ RestaurantMapScreen 종료\n');
    super.dispose();
  }
}