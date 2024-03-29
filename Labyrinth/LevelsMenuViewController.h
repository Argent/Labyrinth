//
//  LevelsMenuViewController.h
//  Labyrinth
//
//  Created by Corina Schemainda on 11.01.14.
//  Copyright (c) 2014 Benjamin Otto. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LevelsMenuViewController : UIViewController
<UICollectionViewDataSource,UICollectionViewDelegate>

@property (nonatomic, strong) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *levels;
@property (nonatomic, strong) NSMutableArray* dataArray;

@property (nonatomic) BOOL startEditor;

@end
