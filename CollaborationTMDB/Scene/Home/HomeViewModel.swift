//
//  HomeViewModel.swift
//  CollaborationTMDB
//
//  Created by Minjae Kim on 10/10/24.
//

import Foundation
import RxSwift
import RxCocoa

enum MediaType {
    case movie
    case tv
}

final class HomeViewModel {
    private let tmdbRepository: TMDBRepository
    private let disposeBag: DisposeBag
    private let movieGenreData = BehaviorRelay(value: [HomeGenre]())
    private let tvGenreData = BehaviorRelay(value: [HomeGenre]())
    
    var input = Input()
    var output = Output()
    
    init() {
        self.tmdbRepository = TMDBRepository.shared
        self.disposeBag = DisposeBag()
        transform()
    }
}

extension HomeViewModel {
    struct Input {
        var viewDidLoad = PublishRelay<Void>()
        var randomMedia = PublishRelay<(type: MediaType, genreIds: [Int])>()
        var movieCellTap = PublishRelay<HomeMedia>()
        var tvCellTap = PublishRelay<HomeMedia>()
        var saveButtonTap = PublishRelay<HomeMedia>()
    }
    
    struct Output {
        var movieData = PublishRelay<[HomeMedia]>()
        var tvData = PublishRelay<[HomeMedia]>()
        var genreData = PublishRelay<String>()
        var movieCellTapData = PublishRelay<DetailViewInput>()
        var tvCellTapData = PublishRelay<DetailViewInput>()
        var saveButtonTap = PublishRelay<Bool>()
    }
    
    private func transform() {
        input.viewDidLoad
            .bind(with: self) { owner, _ in
                owner.fetchData()
            }
            .disposed(by: disposeBag)
        
        input.randomMedia
            .bind(with: self) { owner, genreData in
                let array: [String]
                switch genreData.type {
                case .movie:
                    array = genreData.genreIds.compactMap { id in
                        owner.movieGenreData.value.first { $0.id == id }?.title
                    }
                case .tv:
                    array = genreData.genreIds.compactMap { id in
                        owner.tvGenreData.value.first { $0.id == id }?.title
                    }
                }
                let result = array.joined(separator: " ")
                
                owner.output.genreData.accept(result)
            }
            .disposed(by: disposeBag)
        
        input.movieCellTap
            .bind(with: self) { owner, movie in
                var detailViewInput: DetailViewInput = .init(
                    id: movie.id,
                    title: movie.title,
                    backdropPath: movie.backdropPath,
                    voteAverage: movie.voteAverage,
                    overview: movie.overview,
                    mediaType: .movie)
                detailViewInput.mapIsSavedMedia()
                owner.output.movieCellTapData.accept(detailViewInput)
            }
            .disposed(by: disposeBag)
        
        input.tvCellTap
            .bind(with: self) { owner, tv in
                var detailViewInput: DetailViewInput = .init(
                    id: tv.id,
                    title: tv.title,
                    backdropPath: tv.backdropPath,
                    voteAverage: tv.voteAverage,
                    overview: tv.overview,
                    mediaType: .tv)
                detailViewInput.mapIsSavedMedia()
                owner.output.movieCellTapData.accept(detailViewInput)
            }
            .disposed(by: disposeBag)
        
        input.saveButtonTap
            .bind(with: self) { owner, media in
                owner.addOrExistRecord(media)
            }
            .disposed(by: disposeBag)
    }
}

extension HomeViewModel {
    enum Action {
        case viewDidLoad
        case randomMedia(_ type: MediaType, genreIds: [Int])
        case movieCellTap(_ movie: HomeMedia)
        case tvCellTap(_ tv: HomeMedia)
        case saveButtonTap(_ media: HomeMedia)
    }
    
    func action(_ action: Action) {
        switch action {
        case .viewDidLoad:
            input.viewDidLoad.accept(())
        case .randomMedia(let type, let genreIds):
            input.randomMedia.accept((type, genreIds))
        case .movieCellTap(let movie):
            input.movieCellTap.accept(movie)
        case .tvCellTap(let tv):
            input.tvCellTap.accept(tv)
        case .saveButtonTap(let media):
            input.saveButtonTap.accept(media)
        }
    }
}

extension HomeViewModel {
    private func fetchData() {
        fetchGenreMovie()
        fetchGenreTV()
        fetchMovie()
        fetchTV()
    }
    
    private func fetchGenreMovie() {
        tmdbRepository.requestGenreMovie()
            .asDriver(onErrorJustReturn: .failure(.badRequest))
            .drive(with: self) { owner, result in
                switch result {
                case .success(let data):
                    owner.movieGenreData.accept(data)
                case .failure(let error):
                    print("fetchGenreMovie", error)
                }
            } onCompleted: { _ in
                print("fetchGenreMovie onCompleted")
            } onDisposed: { _ in
                print("fetchGenreMovie onDisposed")
            }
            .disposed(by: disposeBag)
    }
    
    private func fetchGenreTV() {
        tmdbRepository.requestGenreTV()
            .asDriver(onErrorJustReturn: .failure(.badRequest))
            .drive(with: self) { owner, result in
                switch result {
                case .success(let data):
                    owner.tvGenreData.accept(data)
                case .failure(let error):
                    print("fetchGenreMovie", error)
                }
            } onCompleted: { _ in
                print("fetchGenreMovie onCompleted")
            } onDisposed: { _ in
                print("fetchGenreMovie onDisposed")
            }
            .disposed(by: disposeBag)
    }
    
    private func fetchMovie() {
        tmdbRepository.requestTrendingMovie()
            .asDriver(onErrorJustReturn: .failure(.badRequest))
            .drive(with: self) { owner, result in
                switch result {
                case .success(let data):
                    owner.output.movieData.accept(data)
                case .failure(let error):
                    print("fetchMovie", error)
                }
            } onCompleted: { _ in
                print("fetchMovie onCompleted")
            } onDisposed: { _ in
                print("fetchMovie onDisposed")
            }
            .disposed(by: disposeBag)
    }
    
    private func fetchTV() {
        tmdbRepository.requestTrendingTV()
            .asDriver(onErrorJustReturn: .failure(.badRequest))
            .drive(with: self) { owner, result in
                switch result {
                case .success(let data):
                    owner.output.tvData.accept(data)
                case .failure(let error):
                    print("fetchTV", error)
                }
            } onCompleted: { _ in
                print("fetchTV onCompleted")
            } onDisposed: { _ in
                print("fetchTV onDisposed")
            }
            .disposed(by: disposeBag)
    }
}

extension HomeViewModel {
    private func addOrExistRecord(_ media: HomeMedia) {
        let exist = DatabaseRepository.existMovie(movieId: media.id)
        
        if exist {
            output.saveButtonTap.accept(false)
        } else {
            ImageFileManager.addImage(
                urlString: ImageURL.tmdb(image: media.backdropPath).urlString,
                filename: media.title
            ) { result in
                switch result {
                case let .success(filePath):
                    DispatchQueue.main.async { [weak self] in
                        guard let self else { return }
                        DatabaseRepository.addMovie(
                            movie: .init(
                                id: media.id,
                                title: media.title,
                                imageName: filePath,
                                overview: media.overview,
                                voteAverage: media.voteAverage
                            )
                        )
                        output.saveButtonTap.accept(true)
                    }
                case .failure(let failure):
                    print(failure)
                }
            }
        }
    }
}
