//
//  GeometryHelper.m
//  Labyrinth
//
//  Created by Benjamin Otto on 07.12.13.
//  Copyright (c) 2013 Benjamin Otto. All rights reserved.
//

#import "GeometryHelper.h"
#import "NSMutableArray+QueueAdditions.h"
#import "SettingsStore.h"

@implementation GeometryHelper

+(CGPoint)pixelToHex:(CGPoint)pixel gridSize:(CGSize)size{
    CGPoint notRounded = [self pixelToHexNoRound:pixel gridSize:size];
    
    float q = notRounded.x;
    float r = notRounded.y;
    
    q = MIN(MAX(q, 0), size.width -1);
    r = MIN(MAX(r, 0), size.height -1);
    
    return CGPointMake(q, r);
}

+(CGPoint)pixelToHexNoRound:(CGPoint)pixel gridSize:(CGSize)size{
    // axial coordinates
    float q = (1.0/3.0*sqrt(3.0) * pixel.x - 1.0/3.0 * pixel.y) / [SettingsStore sharedStore].hexSize;
    float r = 2.0/3.0 * pixel.y / [SettingsStore sharedStore].hexSize;
    
    // convert to cube coordinates
    float x = q;
    float z = r;
    float y = -x-z;
    
    // hex rounding
    
    float rx = round(x);
    float ry = round(y);
    float rz = round(z);
    
    float x_diff = abs(rx - x);
    float y_diff = abs(ry - y);
    float z_diff = abs(rz - z);
    
    if (x_diff > y_diff && x_diff > z_diff){
        rx = -ry-rz;
    }else if (y_diff > z_diff){
        ry = -rx-rz;
    }else{
        rz = -rx-ry;
    }
    
    // convert cube to odd-r offset
    
    q = rx + (rz - ((int)rz&1)) / 2;
    r = rz - 1;
    
    return CGPointMake(q, r);
}

+(CGPoint)hexToPixel:(CGPoint)hex{
    float size = [[SettingsStore sharedStore]hexSize];
    int r = (int)hex.y;
    int q = (int)hex.x;
    
    float x = (size * sqrt(3) * (q + 0.5 * (r&1))) + ((int)hex.y%2 == 1? -1 *([[SettingsStore sharedStore]width] / 2.0) : [[SettingsStore sharedStore]width] / 2.0);// - ([[SettingsStore sharedStore]width] / 2.0);
    float y = (size * 3/2 * r) + size;
    
    return CGPointMake(x, y);
}

+(NSArray*)getShortestPathFrom:(MazeNode*)startPoint To:(MazeNode*)endPoint{
    
    NSMutableArray *path = [NSMutableArray array];
    [path addObject:startPoint];
    MazeNode *currentNode = startPoint;
    while (!(currentNode.MatrixCoords.x == endPoint.MatrixCoords.x && currentNode.MatrixCoords.y == endPoint.MatrixCoords.y)) {
        MazeNode *minStepsNode = nil;
        for (MazeNode *neighbour in currentNode.neighbours) {
            if (neighbour.steps > -1) {
                if (!minStepsNode || minStepsNode.steps > neighbour.steps)
                    minStepsNode = neighbour;
            }
        }
        if (!minStepsNode){
            NSLog(@"no path found");
            return [NSArray array];
        }
        
        [path addObject:minStepsNode];
        currentNode = minStepsNode;
    }
    
    return path;
    
}


+(void)solveMazeFrom:(MazeNode*)startPoint To:(MazeNode*)endPoint Matrix:(NSArray*)matrix{
    for (int x = 0; x < matrix.count; x++) {
        for (int y = 0; y < ((NSArray*)matrix[0]).count; y++) {
            MazeNode *node = matrix[x][y];
            if (![node isEqual:[NSNull null]]){
                node.steps = -1;
            }
        }
    }
    
    endPoint.steps = 0;
    
    // MazeNode *currentNode = endPoint;
    
    NSMutableArray *nodeList = [NSMutableArray array];
    [nodeList addObject:endPoint];
    
    while (nodeList.count > 0) {
        
        MazeNode *currentNode = [nodeList dequeue];
        NSArray *neighbours = currentNode.neighbours;
        for (MazeNode *node in neighbours) {
            int nextStepValue = currentNode.steps + 1;
            if (!node.isWall && (node.steps == -1 || nextStepValue < node.steps)) {
                node.steps = nextStepValue;
                [nodeList enqueue:node];
            }
        }
    }
    
    NSLog(@"solved");
    
}

+(NSArray*)getNeighboursFrom:(CGPoint) point GridSize:(CGSize)gridSize{
    
    NSArray *neighboursTmp = [self getNeighboursFrom:point];
    NSMutableArray *neighbours = [NSMutableArray array];
    
    for (NSValue *val in neighboursTmp) {
        CGPoint point = [val CGPointValue];
        if ((point.x >= 0 && point.x < gridSize.width) &&
            (point.y >= 0 && point.y < gridSize.height)) {
            bool even = (int)point.y % 2 == 0;
            if ((even && point.x >= 0 && point.x < gridSize.height -1) ||
                (!even && point.x > 0 && point.x < gridSize.width)) {
                [neighbours addObject:val];
            }
        }
    }
    
    return neighbours;
    
}

+(NSArray*)getNeighboursFrom:(CGPoint) point{
    bool even = ((int)point.y) % 2 != 0;
    NSMutableArray *neighboursTmp = [NSMutableArray array];
    if (even) {
        [neighboursTmp addObject:[NSValue valueWithCGPoint:CGPointMake(point.x + 1, point.y)]];
        [neighboursTmp addObject:[NSValue valueWithCGPoint:CGPointMake(point.x, point.y - 1)]];
        [neighboursTmp addObject:[NSValue valueWithCGPoint:CGPointMake(point.x - 1, point.y - 1)]];
        [neighboursTmp addObject:[NSValue valueWithCGPoint:CGPointMake(point.x - 1, point.y)]];
        [neighboursTmp addObject:[NSValue valueWithCGPoint:CGPointMake(point.x - 1, point.y + 1)]];
        [neighboursTmp addObject:[NSValue valueWithCGPoint:CGPointMake(point.x, point.y + 1)]];
        
    }else {
        [neighboursTmp addObject:[NSValue valueWithCGPoint:CGPointMake(point.x + 1, point.y)]];
        [neighboursTmp addObject:[NSValue valueWithCGPoint:CGPointMake(point.x + 1, point.y - 1)]];
        [neighboursTmp addObject:[NSValue valueWithCGPoint:CGPointMake(point.x, point.y - 1)]];
        [neighboursTmp addObject:[NSValue valueWithCGPoint:CGPointMake(point.x - 1, point.y)]];
        [neighboursTmp addObject:[NSValue valueWithCGPoint:CGPointMake(point.x, point.y + 1)]];
        [neighboursTmp addObject:[NSValue valueWithCGPoint:CGPointMake(point.x + 1, point.y + 1)]];
    }
    return neighboursTmp;
}

+(NSArray*)getPixelNeighboursFrom:(CGPoint)point{
    NSMutableArray *neighboursTmp = [NSMutableArray array];
    [neighboursTmp addObject:[NSValue valueWithCGPoint:CGPointMake(point.x - ([[SettingsStore sharedStore]width] / 2.0), point.y +([[SettingsStore sharedStore]height] * 3.0/4.0))]];
    [neighboursTmp addObject:[NSValue valueWithCGPoint:CGPointMake(point.x + ([[SettingsStore sharedStore]width] / 2.0), point.y + ([[SettingsStore sharedStore]height] * 3.0/4.0))]];
    [neighboursTmp addObject:[NSValue valueWithCGPoint:CGPointMake(point.x + [[SettingsStore sharedStore]width], point.y)]];
    [neighboursTmp addObject:[NSValue valueWithCGPoint:CGPointMake(point.x - [[SettingsStore sharedStore]width], point.y)]];
    [neighboursTmp addObject:[NSValue valueWithCGPoint:CGPointMake(point.x - ([[SettingsStore sharedStore]width] / 2.0), point.y -([[SettingsStore sharedStore]height] * 3.0/4.0))]];
    [neighboursTmp addObject:[NSValue valueWithCGPoint:CGPointMake(point.x + ([[SettingsStore sharedStore]width] / 2.0), point.y - ([[SettingsStore sharedStore]height] * 3.0/4.0))]];
    
    return neighboursTmp;
}

+(bool)isValidMatrixCoord:(CGPoint)coord Matrix:(NSArray*)matrix {
    if (coord.x < 0 || coord.y < 0 || coord.x >= matrix.count || coord.y >= ((NSArray*)matrix[0]).count)
        return NO;
    
    return ![matrix[(int)coord.x][(int)coord.y] isEqual:[NSNull null]];
}

+(bool)isValidDropPoint:(CGPoint)coord Matrix:(NSArray *)matrix {
    bool isValidCoord = [self isValidMatrixCoord:coord Matrix:matrix];
    if (!isValidCoord)
        return NO;
    
    MazeNode *node = matrix[(int)coord.x][(int)coord.y];
    return node.object == nil;
}

+(CGPoint)addOffset:(CGPoint)offset toPoint:(CGPoint)point {
    CGPoint newPoint = CGPointMake(point.x + offset.x, point.y + offset.y);
   // if ((int)offset.y % 2 == 1 /*&& (int)point.y % 2 == 1*/)
   //     newPoint.x += 1;
    
    return newPoint;
}

+(NSArray *)alignToGrid:(MazeObject *)mazeObject Matrix:(NSArray *)matrix TopLeft:(CGPoint)point{
    CGSize gridSize = CGSizeMake(matrix.count, ((NSArray*)matrix[0]).count);
    
    CGPoint matrixCoords = [GeometryHelper pixelToHex:CGPointMake(point.x + [[SettingsStore sharedStore]width] /2.0, point.y + [[SettingsStore sharedStore]height] /2.0) gridSize:gridSize];
    if ((int)matrixCoords.y % 2 == 1 && matrixCoords.x == 0.0)
        matrixCoords.x = matrixCoords.x + 1;
    if ((int)matrixCoords.y % 2 == 0 && matrixCoords.x == matrix.count - 1)
        matrixCoords.x = matrixCoords.x - 1;
    
    MazeNode *node = matrix[(int)matrixCoords.x][(int)matrixCoords.y];
    
    
    CGRect rect = mazeObject.containerView.frame;
    rect.origin.x = node.Anchor.x;
    rect.origin.y = node.Anchor.y;
    /*
     UIView *imgView = mazeObject.containerView;
     if ([imgView isKindOfClass:[UIView class]]){
     ((UIView*)imgView).transform = CGAffineTransformMakeScale(1.0, 1.0);
     rect.size = mazeObject.containerView.frame.size;
     mazeObject.containerView.frame = rect;
     
     }
     */
    
    CGPoint mostLeftNode = CGPointMake(FLT_MAX, FLT_MAX);
    for (NSValue *val in mazeObject.objectCoordinates) {
        CGPoint matrixOffset = [val CGPointValue];
        if ((matrixOffset.x < mostLeftNode.x )||
            (matrixOffset.x == mostLeftNode.x && (int)matrixOffset.y%2 == 0)){
            mostLeftNode.x = matrixOffset.x;
            mostLeftNode.y = matrixOffset.y;
        }
    }
    
    NSMutableArray *coordsToCheck = [NSMutableArray array];
    
    CGPoint mostLeftNodeCoords = CGPointMake(rect.origin.x, (rect.origin.y + node.Size) + mostLeftNode.y * node.Size * 1.5);
    //if ((int)mostLeftNode.y % 2 == 0)
    //    mostLeftNodeCoords.x -= node.width / 2;
    mostLeftNodeCoords.x += node.Size / 2;
    CGPoint mostLeftNodeMatrixCoords = [GeometryHelper pixelToHex:mostLeftNodeCoords gridSize:gridSize];
    
    [coordsToCheck addObject:[NSValue valueWithCGPoint:mostLeftNodeMatrixCoords]];
    
    for (NSValue *val in mazeObject.objectCoordinates) {
        CGPoint matrixOffset = [val CGPointValue];
        if (!(mostLeftNode.x == matrixOffset.x && mostLeftNode.y == matrixOffset.y)){
            CGPoint newMatrixCoords = CGPointMake(mostLeftNodeMatrixCoords.x - (mostLeftNode.x - matrixOffset.x), mostLeftNodeMatrixCoords.y - (mostLeftNode.y - matrixOffset.y));
            if ((int)newMatrixCoords.y % 2 == 1 && (int)matrixOffset.y % 2 == 1)
                [coordsToCheck addObject:[NSValue valueWithCGPoint:CGPointMake(newMatrixCoords.x + 1, newMatrixCoords.y)]];
            else
                [coordsToCheck addObject:[NSValue valueWithCGPoint:newMatrixCoords]];
            
        }
    }

    return coordsToCheck;
}

+(NSArray *)alignToValidGrid:(MazeObject *)mazeObject Matrix:(NSArray *)matrix TopLeft:(CGPoint)point searchRadius:(int)radius{
        CGSize gridSize = CGSizeMake(matrix.count, ((NSArray*)matrix[0]).count);
    NSArray *coordsToCheck = [self alignToGrid:mazeObject Matrix:matrix TopLeft:point];
    
    bool allValid = YES;
    for (NSValue *val in coordsToCheck) {
        allValid =  allValid && [self isValidDropPoint:[val CGPointValue] Matrix:matrix];
    }
    
    if (allValid) {
        //NSLog(@"%@", mazeObject.objectCoordinates);
        //NSLog(@"%@", coordsToCheck);
        return coordsToCheck;
    }
    
    NSMutableArray *tmpVals = [NSMutableArray array];
    NSMutableArray *neighbourOffsets = (NSMutableArray*)[self getPixelNeighboursFrom:CGPointMake(0, 0)];
    
    for (int i = 0; i < radius && neighbourOffsets.count > 0 && !allValid ; i++) {
        CGPoint offset = [[neighbourOffsets dequeue]CGPointValue];
        allValid = YES;
        
        bool outOfBounds = false;
        for (NSValue *val in coordsToCheck) {
            CGPoint tmpCoords = [self hexToPixel:[val CGPointValue]];
            CGPoint tmpPoint = [self addOffset:offset toPoint: tmpCoords];
            CGPoint matrPoint = [self pixelToHexNoRound:tmpPoint gridSize:gridSize];
            outOfBounds = outOfBounds && [self isValidMatrixCoord:matrPoint Matrix:matrix];
            allValid =  allValid && [self isValidDropPoint:matrPoint Matrix:matrix];
            if(allValid)
                [ tmpVals addObject:[NSValue valueWithCGPoint:matrPoint]];
        }
        
        if (!allValid && !outOfBounds)
            [neighbourOffsets addObjectsFromArray:[self getPixelNeighboursFrom:offset]];
        
        if (tmpVals.count > 0 && !allValid)
            [tmpVals removeAllObjects];
    }
    
    //NSLog(@"%@", mazeObject.objectCoordinates);
    //NSLog(@"%@", coordsToCheck);
    //NSLog(@"%@", tmpVals);
    
    if (allValid)
        return tmpVals;
    
    return [NSArray array];
    

}

+(NSArray *)alignToValidGrid:(MazeObject *)mazeObject Matrix:(NSArray *)matrix TopLeft:(CGPoint)point {
    return [self alignToValidGrid:mazeObject Matrix:matrix TopLeft:point searchRadius:100];
}

+(CGRect)rectForObject:(NSArray *)matrixCoords Matrix:(NSArray *)matrix {
    CGPoint mostLeftNode = CGPointMake(FLT_MAX, FLT_MAX);
    CGPoint mostRightNode = CGPointMake(0, FLT_MAX);
    int minY = INT32_MAX;
    int maxY = 0;
    
    for (NSValue *val in matrixCoords) {
        CGPoint matrixOffset = [val CGPointValue];
        if ((matrixOffset.x < mostLeftNode.x )||
            (matrixOffset.x == mostLeftNode.x && (int)matrixOffset.y%2 == 1)){
            mostLeftNode.x = matrixOffset.x;
            mostLeftNode.y = matrixOffset.y;
        }
        
        if ((matrixOffset.x > mostRightNode.x )||
            (matrixOffset.x == mostRightNode.x && (int)matrixOffset.y%2 == 0)){
            mostRightNode.x = matrixOffset.x;
            mostRightNode.y = matrixOffset.y;
        }
    
        minY = MIN(minY, matrixOffset.y);
        maxY = MAX(maxY, matrixOffset.y);
    }
    float size = [[SettingsStore sharedStore]hexSize];
    float yVal = 0;
    for (NSValue *val in matrixCoords) {
        if ([val CGPointValue].y == minY){
            yVal = ((MazeNode*)matrix[(int)[val CGPointValue].x][(int)[val CGPointValue].y]).Anchor.y;
            break;
        }
    }
    
    MazeNode* leftNode = (MazeNode*)matrix[(int)mostLeftNode.x][(int)mostLeftNode.y];
    MazeNode* rightNode = (MazeNode*)matrix[(int)mostRightNode.x][(int)mostRightNode.y];
    
    CGRect rect = CGRectMake(leftNode.Anchor.x , yVal, (rightNode.Anchor.x + rightNode.width ) - leftNode.Anchor.x, (2.0 * size) +  (((maxY - minY) * 1.5 *size)));
    
    return rect;
}

+(NSMutableArray *)generateMatrixWithWidth:(int)width Height:(int)height withImageName:(NSString*)name inContainerView:(UIView*)containerView{
    NSMutableArray *matrix = [NSMutableArray array];
    
    float currentX =  [[SettingsStore sharedStore]width] / 2;
    float currentY = [[SettingsStore sharedStore]height] / 2;
    bool even;
    for (int x = 0; x < width; x++) {
        [matrix addObject:[NSMutableArray array]];
        currentY = [[SettingsStore sharedStore]height]  / 2;
        for (int y = 0; y < height; y++) {
            if(y%2 == 0){
                even = true;
            }else{
                even = false;
            }
            
            if ((even && x < width-1) ||
                (!even && x > 0)){
                
                MazeNode *node = [MazeNode node];
                node.Size = [SettingsStore sharedStore].hexSize;
                node.center = CGPointMake(currentX, currentY);
                node.MatrixCoords = CGPointMake(x, y);
                
                UIImageView *uiImage = [[UIImageView alloc]initWithFrame:node.Frame];
                [uiImage setImage:[UIImage imageNamed:name]];
                [containerView addSubview:uiImage];
                
                node.uiElement = uiImage;
                
                [matrix[x] addObject:node];
            } else {
                [matrix[x] addObject:[NSNull null]];
            }
            currentY += [[SettingsStore sharedStore]height]  * 3/4;
            
            if (!even) {
                currentX += [[SettingsStore sharedStore]width]  / 2;
            } else {
                currentX -= [[SettingsStore sharedStore]width]  / 2;
            }
        }
        
        if ((int)height%2 == 0)
            currentX += [[SettingsStore sharedStore]width] ;
        else
            currentX += [[SettingsStore sharedStore]width]  * 1.5;
    }
    
    
    for (int x = 0; x < matrix.count; x++) {
        for (int y = 0; y < ((NSArray*)matrix[0]).count; y++) {
            MazeNode *node = matrix[x][y];
            if (![node isEqual:[NSNull null]]) {
                CGSize gridSize  = CGSizeMake(width, height);
                NSArray *neigbours = [GeometryHelper getNeighboursFrom:CGPointMake(x, y) GridSize:gridSize];
                for (NSValue *val in neigbours) {
                    CGPoint neigbour = [val CGPointValue];
                    
                    MazeNode *node2 = matrix[(int)neigbour.x][(int)neigbour.y];
                    if (![node2 isEqual:[NSNull null]])
                        [node addNeighbours:node2];
                }
            }
        }
    }
    return matrix;
}

+(NSArray *)cropMatrix:(NSArray *)matrix {
    int minX = INT32_MAX;
    int maxX = 0;
    int minY = INT32_MAX;
    int maxY = 0;
    
    for (int x = 0; x < matrix.count; x++) {
        for (int y = 0; y < ((NSArray*)matrix[0]).count; y++) {
            id obj = matrix[x][y];
            if (![obj isEqual:[NSNull null]] && [obj isKindOfClass:[MazeNode class]]) {
                minX = MIN(minX, x);
                minY = MIN(minY, y);
                maxX = MAX(maxX, x);
                maxY = MAX(maxY, y);
            }
        }
    }
    
    NSMutableArray *newMatrix = [NSMutableArray array];
    for (int x = minX; x <= maxX; x++) {
        [newMatrix addObject:[NSMutableArray array]];
        for (int y = minY; y <= maxY; y++) {
            MazeNode *node = matrix[x][y];
            node.MatrixCoords = CGPointMake(x, y);
            [newMatrix[x] addObject:node];
        }
    }
    
    return newMatrix;
}

+(bool)compareWallObject:(MazeObject *)object1 compareWith:(MazeObject *)object2{
    if((object1.type != object2.type) ||
       (object1.objectNodes.count != object2.objectNodes.count) ||
       (object1.containerView.frame.size.height != object2.containerView.frame.size.height) ||
       (object1.containerView.frame.size.width != object2.containerView.frame.size.width)
       ){
        return NO;
    }else{
        int sameCoord = 0;
        for(int i = 0; i < object1.objectNodes.count; i++){
            CGPoint pointObj1 = [object1.objectCoordinates[i] CGPointValue];
            for(int j = 0; j < object2.objectCoordinates.count; j++){
                CGPoint pointObj2 = [object2.objectCoordinates[j] CGPointValue];
                if((pointObj1.x == pointObj2.x) && (pointObj1.y == pointObj2.y)){
                    sameCoord++;
                }
            }
        }
        if(sameCoord == object1.objectNodes.count)
            return YES;
    }
    return NO;
}

+(MazeObject *)scaleToToolbar:(MazeObject *)object withLength:(NSString *)length{
    float itemSize = [SettingsStore sharedStore].toolbarHeight-40;
    float size = 1;
    if([length isEqualToString:@"width"]){
        size = object.containerView.frame.size.width;
    }else{
        size = object.containerView.frame.size.height;
    }
    if(size > itemSize){
        float scaleFactor = itemSize / size;
        object.containerView.transform = CGAffineTransformMakeScale(object.containerView.transform.a*scaleFactor, object.containerView.transform.a*scaleFactor);
    }
    return object;
}

@end
