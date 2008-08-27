#import "DBConnection.h"

static sqlite3*             theDatabase = nil;

@implementation DBConnection

+ (sqlite3*)getSharedDatabase
{
    if (theDatabase == nil) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *path = [documentsDirectory stringByAppendingPathComponent:@"db1.1.sql"];
        // Open the database. The database was prepared outside the application.
        if (sqlite3_open([path UTF8String], &theDatabase) != SQLITE_OK) {
            // Even though the open failed, call close to properly clean up resources.
            sqlite3_close(theDatabase);
            NSAssert1(0, @"Failed to open database with message '%s'.", sqlite3_errmsg(theDatabase));
            // Additional error handling, as appropriate...
        }
    }
    return theDatabase;
}

const char *cleanup_sql =
    "BEGIN;"
    "DELETE FROM images WHERE updated_at <= (SELECT updated_at FROM images order by updated_at LIMIT 1 OFFSET 1000);"
#if 1
    "DELETE FROM messages WHERE type = 0 and id <= (SELECT id FROM messages WHERE type = 0 ORDER BY id DESC LIMIT 1 OFFSET 200);"
    "DELETE FROM messages WHERE type = 1 and id <= (SELECT id FROM messages WHERE type = 1 ORDER BY id DESC LIMIT 1 OFFSET 200);"
    "DELETE FROM messages WHERE type = 2 and id <= (SELECT id FROM messages WHERE type = 2 ORDER BY id DESC LIMIT 1 OFFSET 200);"
#else
    "DELETE FROM messages WHERE type = 0 and id > (SELECT id FROM messages WHERE type = 0 ORDER BY id DESC LIMIT 1 OFFSET 20);"
    "DELETE FROM messages WHERE type = 1 and id > (SELECT id FROM messages WHERE type = 1 ORDER BY id DESC LIMIT 1 OFFSET 5);"
    "DELETE FROM messages WHERE type = 2 and id > (SELECT id FROM messages WHERE type = 2 ORDER BY id DESC LIMIT 1 OFFSET 5);"
#endif
    "COMMIT"
;

+ (void)deleteOldCache
{
    char *errmsg;
    
    if (sqlite3_exec(theDatabase, cleanup_sql, NULL, NULL, &errmsg) != SQLITE_OK) {
        NSAssert1(0, @"Error: failed to cleanup chache (%s)", errmsg);
    }
}

@end
