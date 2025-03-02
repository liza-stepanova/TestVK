import Foundation

/// Класс для загрузки отзывов.
final class ReviewsProvider {

    private let bundle: Bundle
    private let session = URLSession.shared

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

}

// MARK: - Internal

extension ReviewsProvider {

    typealias GetReviewsResult = Result<Data, GetReviewsError>

    enum GetReviewsError: Error {

        case badURL
        case badData(Error)

    }

    func getReviews(offset: Int = 0, completion: @escaping (GetReviewsResult) -> Void) {
        guard let url = bundle.url(forResource: "getReviews.response", withExtension: "json") else {
            return completion(.failure(.badURL))
        }

        // Симулируем сетевой запрос - не менять
        usleep(.random(in: 100_000...1_000_000))

        do {
            let data = try Data(contentsOf: url)
            completion(.success(data))
        } catch {
            completion(.failure(.badData(error)))
        }
    }
    
    func getPhoto(link: String, completion: @escaping (GetReviewsResult) -> Void) {
        guard let url = URL(string: link) else {
            return completion(.failure(.badURL))
        }
        session.dataTask(with: url) { data, _, error in
            if error == nil, let data = data {
                completion(.success(data))
            } else {
                completion(.failure(.badData(error ?? NSError())))
            }
        }.resume()
        
    }

}
