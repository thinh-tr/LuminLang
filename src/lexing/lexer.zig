const std = @import("std");
const stdout = std.io.getStdOut().writer();
const ascii = std.ascii;
const ArrayList = std.ArrayList;
const LexecalError = @import("./LexecalError.zig").LexingError;
const Token = @import("./Token.zig").Token;
const TokenType = @import("./TokenType.zig").TokenType;

pub const Lexer = struct {
    lines: ArrayList([]const u8), // danh sách chứa tất cả các dòng của source được đọc vào
    tokens: ArrayList(Token), // Danh sách các token đã được tìm thấy

    const Self = @This();

    pub fn init() Lexer {
        return Lexer{
            .lines = ArrayList([]const u8).init(std.heap.page_allocator),
            .tokens = ArrayList(Token).init(std.heap.page_allocator),
        };
    }

    // deinit Lexer
    pub fn deinit(self: *Self) void {
        self.*.lines.deinit();
        self.*.tokens.deinit(); // Giải phóng toàn bộ token sau khi đã sử dụng
    }

    // Hàm quét toàn bộ source và trả ra danh sách các line
    pub fn scanLines(self: *Self, source: []const u8) !void {
        var i: usize = 0; // Biến đếm xét ký tự
        var j: usize = i; // Biến đếm ở ký tự đầu tiên của mỗi dòng mới

        while (i < source.len) {
            if (source[i] == '\n') {
                const line: []const u8 = source[j..i];
                try self.*.lines.append(line);
                j = i + 1; // Bắt đầu dòng mới sau ký tự '\n'
            }
            i += 1;
        }
        // Xử lý dòng cuối cùng nếu không kết thúc bằng '\n'
        if (j < source.len) {
            const line: []const u8 = source[j..source.len];
            try self.*.lines.append(line);
        }
    }

    // Hàm Quét qua toàn bộ source code trong một line và trả ra các token trong đó
    pub fn scanTokens(self: *Self) !void {
        if (self.*.lines.items.len > 0) {
            // Tuần tự phân tích token của từng line có trong danh sách
            for (self.*.lines.items, 0..) |line, line_i| {
                var current_i: usize = 0;
                var added_token_length: usize = 0;
                // Tuần tự xét qua tất cả các ký tự có trong line hiện tại
                while (current_i < line.len) : (current_i += added_token_length) {
                    // Lần lượt kiểm tra các ký tự
                    switch (line[current_i]) {
                        // `()`
                        '(' => {
                            try self.*.tokens.append(Token.init(TokenType.LEFT_PATEN, line[current_i .. current_i + TokenType.LEFT_PATEN_LENGTH], line_i + 1));
                            added_token_length = TokenType.LEFT_PATEN_LENGTH;
                        },
                        ')' => {
                            try self.*.tokens.append(Token.init(TokenType.RIGHT_PATEN, line[current_i .. current_i + TokenType.RIGHT_PATEN_LENGTH], line_i + 1));
                            added_token_length = TokenType.RIGHT_PATEN_LENGTH;
                        },

                        // `{}`
                        '{' => {
                            try self.*.tokens.append(Token.init(TokenType.LEFT_BRACE, line[current_i .. current_i + TokenType.LEFT_BRACE_LENGTH], line_i + 1));
                            added_token_length = TokenType.LEFT_BRACE_LENGTH;
                        },
                        '}' => {
                            try self.*.tokens.append(Token.init(TokenType.RIGHT_BRACE, line[current_i .. current_i + TokenType.RIGHT_BRACE_LENGTH], line_i + 1));
                            added_token_length = TokenType.RIGHT_BRACE_LENGTH;
                        },

                        // `,`
                        ',' => {
                            try self.*.tokens.append(Token.init(TokenType.COMMA, line[current_i .. current_i + TokenType.COMMA_LENGTH], line_i + 1));
                            added_token_length = TokenType.COMMA_LENGTH;
                        },

                        // `.`
                        '.' => {
                            try self.*.tokens.append(Token.init(TokenType.DOT, line[current_i .. current_i + TokenType.DOT_LENGTH], line_i + 1));
                            added_token_length = TokenType.DOT_LENGTH;
                        },

                        // `:`
                        ':' => {
                            try self.*.tokens.append(Token.init(TokenType.COLON, line[current_i .. current_i + TokenType.COLON_LENGTH], line_i + 1));
                            added_token_length = TokenType.COLON_LENGTH;
                        },

                        // `;`
                        ';' => {
                            try self.*.tokens.append(Token.init(TokenType.SEMICOLON, line[current_i .. current_i + TokenType.SEMICOLON_LENGTH], line_i + 1));
                            added_token_length = TokenType.SEMICOLON_LENGTH;
                        },

                        // `[]`
                        '[' => {
                            try self.*.tokens.append(Token.init(TokenType.LEFT_SQUARE_BRACKET, line[current_i .. current_i + TokenType.LEFT_SQUARE_BRACKET_LENGTH], line_i + 1));
                            added_token_length = TokenType.LEFT_SQUARE_BRACKET_LENGTH;
                        },
                        ']' => {
                            try self.*.tokens.append(Token.init(TokenType.RIGHT_SQUARE_BRACKET, line[current_i .. current_i + TokenType.RIGHT_SQUARE_BRACKET_LENGTH], line_i + 1));
                            added_token_length = TokenType.RIGHT_SQUARE_BRACKET_LENGTH;
                        },

                        // `!` | `!=`
                        '!' => {
                            const token: Token = if (line[current_i..].len >= TokenType.BANG_EQUAL_LENGTH and line[current_i + 1] == '=')
                                Token.init(TokenType.BANG_EQUAL, line[current_i .. current_i + TokenType.BANG_EQUAL_LENGTH], line_i + 1)
                            else
                                Token.init(TokenType.BANG, line[current_i .. current_i + TokenType.BANG_LENGTH], line_i + 1);
                            try self.*.tokens.append(token);
                            added_token_length = token.lexeme.len;
                        },

                        // `=` | `==`
                        '=' => {
                            const token: Token = if (line[current_i..].len >= TokenType.EQUAL_EQUAL_LENGTH and line[current_i + 1] == '=')
                                Token.init(TokenType.EQUAL_EQUAL, line[current_i .. current_i + TokenType.EQUAL_EQUAL_LENGTH], line_i + 1)
                            else
                                Token.init(TokenType.EQUAL, line[current_i .. current_i + TokenType.EQUAL_LENGTH], line_i + 1);
                            try self.*.tokens.append(token);
                            added_token_length = token.lexeme.len;
                        },

                        // `>` | `>=`
                        '>' => {
                            const token: Token = if (line[current_i..].len >= TokenType.GREATER_EQUAL_LENGTH and line[current_i + 1] == '=')
                                Token.init(TokenType.GREATER_EQUAL, line[current_i .. current_i + TokenType.GREATER_EQUAL_LENGTH], line_i + 1)
                            else
                                Token.init(TokenType.GREATER, line[current_i .. current_i + TokenType.GREATER_LENGTH], line_i + 1);
                            try self.*.tokens.append(token);
                            added_token_length = token.lexeme.len;
                        },

                        // `<` | `<=`
                        '<' => {
                            const token: Token = if (line[current_i..].len >= TokenType.LESS_EQUAL_LENGTH and line[current_i + 1] == '=')
                                Token.init(TokenType.LESS_EQUAL, line[current_i .. current_i + TokenType.LESS_EQUAL_LENGTH], line_i + 1)
                            else
                                Token.init(TokenType.LESS, line[current_i .. current_i + TokenType.LESS_LENGTH], line_i + 1);
                            try self.*.tokens.append(token);
                            added_token_length = token.lexeme.len;
                        },

                        // `+` | `+=`
                        '+' => {
                            const token: Token = if (line[current_i..].len >= TokenType.PLUS_EQUAL_LENGTH and line[current_i + 1] == '=')
                                Token.init(TokenType.PLUS_EQUAL, line[current_i .. current_i + TokenType.PLUS_EQUAL_LENGTH], line_i + 1)
                            else
                                Token.init(TokenType.PLUS, line[current_i .. current_i + TokenType.PLUS_LENGTH], line_i + 1);
                            try self.*.tokens.append(token);
                            added_token_length = token.lexeme.len;
                        },

                        // `-` | `-=`
                        '-' => {
                            const token = if (line[current_i..].len >= TokenType.MINUS_EQUAL_LENGTH and line[current_i + 1] == '=')
                                Token.init(TokenType.MINUS_EQUAL, line[current_i .. current_i + TokenType.MINUS_EQUAL_LENGTH], line_i + 1)
                            else
                                Token.init(TokenType.MINUS, line[current_i .. current_i + TokenType.MINUS_LENGTH], line_i + 1);
                            try self.*.tokens.append(token);
                            added_token_length = token.lexeme.len;
                        },

                        // `*` | `*=`
                        '*' => {
                            const token: Token = if (line[current_i..].len >= TokenType.STAR_EQUAL_LENGTH and line[current_i + 1] == '=')
                                Token.init(TokenType.STAR_EQUAL, line[current_i .. current_i + TokenType.STAR_EQUAL_LENGTH], line_i + 1)
                            else
                                Token.init(TokenType.STAR, line[current_i .. current_i + TokenType.STAR_LENGTH], line_i + 1);
                            try self.*.tokens.append(token);
                            added_token_length = token.lexeme.len;
                        },

                        // `/` | `/=`
                        '/' => {
                            const token: Token = if (line[current_i..].len >= TokenType.SLASH_EQUAL_LENGTH and line[current_i + 1] == '=')
                                Token.init(TokenType.SLASH_EQUAL, line[current_i .. current_i + TokenType.SLASH_EQUAL_LENGTH], line_i + 1)
                            else
                                Token.init(TokenType.SLASH, line[current_i .. current_i + TokenType.SLASH_LENGTH], line_i + 1);
                            try self.*.tokens.append(token);
                            added_token_length = token.lexeme.len;
                        },

                        // `%` | `%=`
                        '%' => {
                            const token: Token = if (line[current_i..].len >= TokenType.PERCENT_EQUAL_LENGTH and line[current_i + 1] == '=')
                                Token.init(TokenType.PERCENT_EQUAL, line[current_i .. current_i + TokenType.PERCENT_EQUAL_LENGTH], line_i + 1)
                            else
                                Token.init(TokenType.PERCENT, line[current_i .. current_i + TokenType.PERCENT_LENGTH], line_i + 1);
                            try self.*.tokens.append(token);
                            added_token_length = token.lexeme.len;
                        },

                        // Trường hợp bắt đầu bằng `'` -> Có thể là character literallitera
                        '\'' => {
                            // Duyệt và tìm char `'` tiếp theo
                            var next_i: usize = current_i + 1;
                            while (next_i < line.len and line[next_i] != '\'') {
                                next_i += 1;    // Tăng next_i lên 1 nếu vẫn còn torng phạm vi của len và chưa tìm được `'`
                            }
                            // Kiểm tra sau khi đã thoát vòng lặp
                            // Trường hợp không tìm được
                            if (next_i == line.len) {
                                try reportLexecalError(LexecalError.IlligalCharacterLiteral, line_i + 1, line, line[current_i]);
                                return LexecalError.IlligalCharacterLiteral;
                            }
                            // Trường hợp đã tìm được `'`
                            const literal: []const u8 = line[current_i..next_i + 1];
                            if (literal.len == 3) {
                                const token: Token = Token.init(TokenType.CHAR_LITERAL, literal, line_i + 1);
                                try self.*.tokens.append(token);
                                added_token_length = token.lexeme.len;
                            } else {
                                try reportLexecalError(LexecalError.IlligalCharacterLiteral, line_i + 1, line, line[current_i]);
                                return LexecalError.IlligalCharacterLiteral;
                            }
                        },

                        // Bắt đầu xét các trường hợp như từ khoá, literal hoặc các trường hợp khác
                        else => {
                            try reportLexecalError(LexecalError.UndefinedToken, line_i + 1, line, line[current_i]);
                            return LexecalError.IlligalCharacterLiteral; // Trả ra lexecal error và kết thúc hàm
                        },
                    }
                }
            }
        }
    }

    // Hàm báo lỗi không thể xác định được token
    fn reportLexecalError(err: LexecalError, line: u128, str_line: []const u8, char: u8) !void {
        try stdout.print("Error `{!}` at line {}:\n\t{s}\n\t(error at: `{c}`)\n", .{ err, line, str_line, char });
    }
};

// Testing

test "testing scanTokens function" {
    var lexer = Lexer.init();
    defer lexer.deinit();

    try lexer.scanLines(
        \\'c';
        \\'d''e';
        \\'f;
    );

    try lexer.scanTokens();

    for (lexer.lines.items) |line| {
        std.debug.print("{s}\n", .{line});
    }

    for (lexer.tokens.items) |token| {
        std.debug.print("{}, '{s}', line: {}\n", .{ token.token_type, token.lexeme, token.line });
    }
}
