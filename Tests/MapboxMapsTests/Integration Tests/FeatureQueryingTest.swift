import XCTest
@testable import MapboxMaps

internal class FeatureQueryingTest: MapViewIntegrationTestCase {

    // MARK: - Test querying a rendered map for features.

    /*
     The purpose of this test is to ensure features are returned when querying
     a default style. It does this zooming into an area with dense features,
     and querying the center of the map to ensure there is a populated array of
     features returned.
     */

    // Seattle's Pike Place Market
    let centerCoordinate = CLLocationCoordinate2D(latitude: 47.609519,
                                                  longitude: -122.341647)

    internal func testQueryAtPoint() {
        style?.uri = .streets

        let featureQueryExpectation = XCTestExpectation(description: "Wait for features to be queried.")

        didFinishLoadingStyle = { mapView in

            mapView.mapboxMap.setCamera(to: CameraOptions(center: self.centerCoordinate,
                                    zoom: 15.0))
        }

        mapView.mapboxMap.onNext(event: .mapLoaded) { [weak self] _ in
            guard let mapView = self?.mapView else { return }

            // Given
            let centerPoint = mapView.center

            // When
            mapView.mapboxMap.queryRenderedFeatures(with: centerPoint) { result in
                switch result {
                case .success(let features):
                    if features.count > 0 {
                        featureQueryExpectation.fulfill()
                    } else {
                        XCTFail("No features found")
                    }
                case .failure:
                    XCTFail("Feature querying failed")
                }
            }
        }

        wait(for: [featureQueryExpectation], timeout: 5.0)
    }

    internal func testQueryInRectWithFilter() {
        style?.uri = .streets

        let featureQueryExpectation = XCTestExpectation(description: "Wait for features to be queried.")

        didFinishLoadingStyle = { mapView in
            mapView.mapboxMap.setCamera(to: CameraOptions(center: self.centerCoordinate,
                                    zoom: 15.0))
        }

        didBecomeIdle = { mapView in
            // Given
            let queryRect = CGRect(x: mapView.center.x - 25,
                                   y: mapView.center.y - 25,
                                   width: 50,
                                   height: 50)

            // When
            mapView.mapboxMap.queryRenderedFeatures(with: queryRect) { unfilteredFeatures in
                let filter = Exp(.eq) {
                    "$type"
                    "Point"
                }

                let options = RenderedQueryOptions(layerIds: nil, filter: filter)
                mapView.mapboxMap.queryRenderedFeatures(with: queryRect, options: options) { filteredFeatures in
                    if case .success(let unfilteredFeatures) = unfilteredFeatures,
                       case .success(let filteredFeatures) = filteredFeatures {

                        let expectedFilteredFeatures = unfilteredFeatures.filter { queriedFeature in
                            if case .point = queriedFeature.feature.geometry {
                                return true
                            } else {
                                return false
                            }
                        }

                        // Then
                        if expectedFilteredFeatures.count == filteredFeatures.count {
                            featureQueryExpectation.fulfill()
                        } else {
                            XCTFail("Expected \(expectedFilteredFeatures.count) features, got \(filteredFeatures.count) instead.")
                        }
                    } else {
                        XCTFail("Feature querying failed.")
                    }
                }
            }
        }

        wait(for: [featureQueryExpectation], timeout: 5.0)
    }

    internal func testQueryForGeometry() {
        style?.uri = .streets

        let featureQueryExpectation = XCTestExpectation(description: "Wait for features to be queried.")

        didFinishLoadingStyle = { mapView in

            mapView.mapboxMap.setCamera(to: CameraOptions(center: self.centerCoordinate,
                                    zoom: 15.0))
        }

        mapView.mapboxMap.onNext(event: .mapLoaded) { [weak self] _ in
            guard let mapView = self?.mapView else { return }

            // Given
            let coordinates = [
                CLLocationCoordinate2D(latitude: 43.58039085560784, longitude: -101.337890625),
                CLLocationCoordinate2D(latitude: 36.87962060502676, longitude: -108.544921875),
                CLLocationCoordinate2D(latitude: 37.09023980307208, longitude: -97.119140625),
                CLLocationCoordinate2D(latitude: 43.58039085560784, longitude: -101.337890625)
            ]
                .map { mapView.mapboxMap.point(for: $0) }

            // When
            mapView.mapboxMap.queryRenderedFeatures(with: coordinates) { result in
                switch result {
                case .success(let features):
                    if features.count > 0 {
                        featureQueryExpectation.fulfill()
                    } else {
                        XCTFail("No features found")
                    }
                case .failure:
                    XCTFail("Feature querying failed")
                }
            }
        }

        wait(for: [featureQueryExpectation], timeout: 5.0)
    }
}
