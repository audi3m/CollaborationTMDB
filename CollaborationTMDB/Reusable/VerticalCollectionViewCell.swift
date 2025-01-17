//
//  VerticalCollectionViewCell.swift
//  CollaborationTMDB
//
//  Created by J Oh on 10/10/24.
//

import UIKit
import SnapKit
import Kingfisher

final class VerticalCollectionViewCell: UICollectionViewCell {
    static let id = "VerticalCollectionViewCell"
    
    private let posterImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configureHierarchy()
        self.configureLayout()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
    }
}

// Data
extension VerticalCollectionViewCell {
   func configureData(_ path: String) {
      posterImageView.kf.setImage(with: URL(string: ImageURL.tmdb(image: path).urlString))
   }
   
   func configureData(filePath: String) {
      posterImageView.image = ImageFileManager.loadImage(filename: filePath)
   }
   
   func configureWithoutData() {
      posterImageView.backgroundColor = .systemGray5
   }
}

// View
extension VerticalCollectionViewCell {
    private func configureHierarchy() {
        self.addSubview(posterImageView)
    }
    
    private func configureLayout() {
        posterImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

