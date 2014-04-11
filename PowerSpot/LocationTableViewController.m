//
//  LocationTableViewController.m
//  locachiguide
//
//  The MIT License (MIT)

//  Copyright (c) 2014, Kazuomatz

/* Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.*/

#import "LocationTableViewController.h"
#import "LocationDetailViewController.h"
@interface LocationTableViewController ()

@end

@implementation LocationTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self requestData];
    self.title = @"ふじのくにエンゼルパワースポット";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.dataArray count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"tableCell" forIndexPath:indexPath];
    NSDictionary *dic = self.dataArray[indexPath.row];
    [cell.textLabel setText:dic[@"名称"]];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"toMapSeque" sender:self.dataArray[indexPath.row]];
}

#pragma mark - Navigation
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ( [[segue identifier] isEqualToString:@"toMapSeque"] ) {
        LocationDetailViewController *nextViewController = [segue destinationViewController];
        //ロケーションデータをViewControllerに渡す
        nextViewController.location = sender;
    }
}

#pragma mark - Request Data
-(void)requestData {
    
    //ファイルが保存されていたらhttpアクセスはしない
    if ( [[NSFileManager defaultManager] fileExistsAtPath:[self getSavePath] isDirectory:NO] ) {
        self.dataArray = [NSArray arrayWithContentsOfFile:[self getSavePath]];
        [self.tableView reloadData];
    }
    //ファイルが保存されていなければhttpアクセスをしてデータを取得する
    else {
        NSString *urlStr = CSV_URL;
        NSURL *url = [NSURL URLWithString:urlStr];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [request setHTTPMethod:@"GET"];
        
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                   if ( error ) {
                                       //エラー処理
                                   }
                                   else if (data) {
                                       //CSVファイルをパースする
                                       self.dataArray = [self parseData:data];
                                       [self.tableView reloadData];
                                   }
                                   else {
                                       
                                   }
                               }];
    }
}

#pragma mark - Parse Data
-(NSArray*)parseData:(NSData*)data {
    
    //Shift-JISエンコードでNSStringに変換
    NSString *dataString = [[NSString alloc]initWithData:data encoding:NSShiftJISStringEncoding];
    
    //CSVをパース
    //改行文字でセパレート
    NSArray *lines = [dataString componentsSeparatedByString:@"\n"];
    NSInteger lineNumber = 0;
    NSArray *keys;
    NSMutableArray *dataArray = [NSMutableArray new];
    
    for (NSString *row in lines) {
        // 「\r」が含まれている可能性があるので除去する
        NSString *newRow = [row stringByReplacingOccurrencesOfString:@"\r" withString:@""];
        if ( lineNumber == 0 ) {
            //1行目が項目名になるためNSDictionaryのKeyとする
            keys =  [newRow componentsSeparatedByString:@","];
        }
        else {
            //カンマでセパレートしてNSDictionaryを作成
            NSArray *items = [newRow componentsSeparatedByString:@","];
            if ( [items count] == [keys count]) {
                NSInteger i = 0;
                NSMutableDictionary *dic = [NSMutableDictionary new];
                for ( NSString *key in keys) {
                    dic[key] = items[i++];
                }
                [dataArray addObject:dic];
            }
        }
        lineNumber++;
    }
    
    //受信したデータをLibrary Cacheに保存
    [dataArray writeToFile:[self getSavePath] atomically:YES];
    
    return dataArray;
}

#pragma mark - ファイルを保存するパス
-(NSString*)getSavePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *dir = [paths objectAtIndex:0];
    return [NSString stringWithFormat:@"%@/%@",dir,CSV_SAVE_FILE_NAME];
}
@end
