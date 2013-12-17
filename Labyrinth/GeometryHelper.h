//
//  GeometryHelper.h
//  Labyrinth
//
//  Created by Benjamin Otto on 07.12.13.
//  Copyright (c) 2013 Benjamin Otto. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MazeNode.h"
#import "MazeObject.h"

@interface GeometryHelper : NSObject

+(CGPoint)pixelToHex:(CGPoint)pixel gridSize:(CGSize)size;
+(CGPoint)hexToPixel:(CGPoint)hex;
+(NSArray*)getShortestPathFrom:(MazeNode*)startPoint To:(MazeNode*)endPoint;
+(void)solveMazeFrom:(MazeNode*)startPoint To:(MazeNode*)endPoint Matrix:(NSArray*)matrix;
+(NSArray*)getNeighboursFrom:(CGPoint) point GridSize:(CGSize)gridSize;
+(bool)isValidMatrixCoord:(CGPoint)coord Matrix:(NSArray*)matrix;
+(bool)isValidDropPoint:(CGPoint)coord Matrix:(NSArray*)matrix;
+(CGPoint)addOffset:(CGPoint)offset toPoint:(CGPoint)point;
+(NSArray*)alignToGrid:(MazeObject*)object Matrix:(NSArray*)matrix TopLeft:(CGPoint)point;
+(NSArray*)alignToValidGrid:(MazeObject*)object Matrix:(NSArray*)matrix TopLeft:(CGPoint)point;
+(NSArray*)alignToValidGrid:(MazeObject *)mazeObject Matrix:(NSArray *)matrix TopLeft:(CGPoint)point searchRadius:(int)radius;
+(CGRect)rectForObject:(NSArray*)matrixCoords Matrix:(NSArray*)matrix;
+(NSMutableArray *)generateMatrixWithWidth:(int)width Height:(int)height withImageName:(NSString*)name inContainerView:(UIView*)containerView;
+(NSArray*)cropMatrix:(NSArray*)matrix;
+(bool)compareWallObject:(MazeObject *)object1 compareWith:(MazeObject *)object2;
+(MazeObject*)scaleToToolbar:(MazeObject *)object withLength:(NSString*)length;

@end
