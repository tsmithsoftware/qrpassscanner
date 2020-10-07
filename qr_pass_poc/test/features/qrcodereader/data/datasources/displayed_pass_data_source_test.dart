import 'dart:convert';

import 'package:matcher/matcher.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:qr_pass_poc/core/error/exception.dart';
import 'package:qr_pass_poc/features/qrcodereader/data/datasources/displayed_pass_remote_data_source.dart';
import 'package:qr_pass_poc/features/qrcodereader/data/models/displayed_pass_model.dart';
import 'package:qr_pass_poc/features/qrcodereader/data/models/pass_validation_model.dart';

import '../../../../fixtures/fixture_reader.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  DisplayedPassRemoteDataSourceImpl dataSource;
  MockHttpClient mockHttpClient;

  setUp(() {
    mockHttpClient = MockHttpClient();
    dataSource = DisplayedPassRemoteDataSourceImpl(client: mockHttpClient);
  });

  void setUpMockHttpClientSuccess200() {
    when(mockHttpClient.post(any, headers: anyNamed('headers'))).thenAnswer(
          (_) async => http.Response(fixture('pass.json'), 200),
    );
  }

  void setUpMockHttpClientFailure404() {
    when(mockHttpClient.post(any, headers: anyNamed('headers'))).thenAnswer(
          (_) async => http.Response('Something went wrong', 404),
    );
  }

  group('getDisplayedPass', () {
    final tNumber = 1;

    test(
      'should perform a POST request on a URL with number being the endpoint and with application/json header',
          () {
        setUpMockHttpClientSuccess200();
        // act
        dataSource.getDisplayedPass(tNumber);
        // assert
        verify(mockHttpClient.post(
          'https://voj6te3tx9.execute-api.eu-west-1.amazonaws.com/dev/qrpass',
          body: jsonEncode(PassValidationModel(passId: tNumber).toJson()),
          headers: {'Content-Type': 'application/json'},
        ));
      },
    );

    test(
      'should return DisplayedPass when the response code is 200 (success)',
          () async {
            final tPassModel =
            DisplayedPassModel.fromJson(json.decode(fixture('pass.json')));
        // arrange
        setUpMockHttpClientSuccess200();
        // act
        final result = await dataSource.getDisplayedPass(tNumber);
        // assert
        expect(result, equals(tPassModel));
      },
    );

    test(
      'should throw a ServerException when the response code is 404 or other',
          () async {
        // arrange
        setUpMockHttpClientFailure404();
        // act
        final call = dataSource.getDisplayedPass;
        // assert
        expect(() => call(tNumber), throwsA(TypeMatcher<ServerException>()));
      },
    );
  });
}