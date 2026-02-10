Sub Bnk_Frost_All_Cash()

    Application.ScreenUpdating = False
    
    '-----------------------------------------------------------------------------------
    'Skip over any error lines for this whole thing. (This is suboptimal, and a bit lazy.)
    '-----------------------------------------------------------------------------------
    On Error Resume Next
    
    
    
    '-----------------------------------------------------------------------------------
    'Reorder Columns
    '-----------------------------------------------------------------------------------
    Reorder_BankDowload_Columns_v2
    
    
    '-----------------------------------------------------------------------------------
    'Obtain the total number of rows.
    '-----------------------------------------------------------------------------------
    RowCount = LastRowOrColumn(1, 11, True)
    
    '-----------------------------------------------------------------------------------
    'Find the first and last date in the range.
    '-----------------------------------------------------------------------------------
    StartDate = Range("D2").Value
        For i = 2 To RowCount
            TempDate = Range("D" & i).Value
            If TempDate < StartDate Then StartDate = TempDate
        Next i
    
    EndDate = Range("D2").Value
        For i = 2 To RowCount
            TempDate = Range("D" & i).Value
            If TempDate > EndDate Then EndDate = TempDate
        Next i
    
    'Columns("L:P").Delete
    'Columns("L:L").Delete
    
    '-----------------------------------------------------------------------------------
    'Parse Data Column
    '-----------------------------------------------------------------------------------
        'Range("L2") = "=SUBSTITUTE(SUBSTITUTE(SUBSTITUTE(SUBSTITUTE(SUBSTITUTE(SUBSTITUTE(SUBSTITUTE(SUBSTITUTE(SUBSTITUTE(TRIM(CLEAN(SUBSTITUTE(K2,""   "",CHAR(124)))),"" :  "","":""),"" : "","":""),""||||||"",""|""),""|||||"",""|""),""||||"",""|""),""|||"",""|""),""||"",""|""),""| "",""|""),"": "","":"")"
        Range("L2") = "=SUBSTITUTE(SUBSTITUTE(SUBSTITUTE(SUBSTITUTE(SUBSTITUTE(SUBSTITUTE(SUBSTITUTE(SUBSTITUTE(SUBSTITUTE(SUBSTITUTE(TRIM(CLEAN(SUBSTITUTE(K2,""   "",CHAR(124)))),"" :  "","":""),"" : "","":""),""||||||"",""|""),""|||||"",""|""),""||||"",""|""),""|||"",""|""),""||"",""|""),""| "",""|""),"": "","":""),""'"","""")"
        
        Range("L2").Select
            Selection.Copy
        Range("L3:L" & RowCount).Select
            ActiveSheet.Paste
        Range("L2:L" & RowCount).Select
        Application.CutCopyMode = False
        Selection.Copy
        Selection.PasteSpecial _
            Paste:=xlPasteValues, _
            Operation:=xlNone, _
            SkipBlanks:=False, _
            Transpose:=False
        Range("K1").Select
        Application.CutCopyMode = False
        Selection.Cut _
            Destination:=Range("L1")
        Columns("K:K").Select
            Selection.Delete Shift:=xlToLeft
        Range("K2:K" & RowCount).Select
            Selection.TextToColumns _
                Destination:=Range("K2"), _
                DataType:=xlDelimited, _
                TextQualifier:=xlDoubleQuote, _
                ConsecutiveDelimiter:=False, _
                Tab:=False, _
                Semicolon:=False, _
                Comma:=False, _
                Space:=False, _
                Other:=True, _
                OtherChar:="|", _
                FieldInfo:=Array(Array(1, 1), Array(2, 1), Array(3, 1), Array(4, 1), Array(5, 1), Array(6, 1), Array(7, 1)), TrailingMinusNumbers:=True
        Columns("K:S").Select
        Columns("K:S").EntireColumn.AutoFit
        
        Columns("K:K").Select
            Selection.Replace _
                What:="Transfer-Transfer ", _
                Replacement:="", _
                LookAt:=xlPart, _
                SearchOrder:=xlByRows, _
                MatchCase:=False, _
                SearchFormat:=False, _
                ReplaceFormat:=False
        Columns("K:K").Select
            Selection.Replace _
                What:="To Line-Advance-Advance ", _
                Replacement:="", _
                LookAt:=xlPart, _
                SearchOrder:=xlByRows, _
                MatchCase:=False, _
                SearchFormat:=False, _
                ReplaceFormat:=False
    
    
    '-----------------------------------------------------------------------------------
    'Create headings for parsed data set
    '-----------------------------------------------------------------------------------
    Range("L1") = "Processor"
    Range("M1") = "Entry Desc."
    Range("N1") = "MS Co Name"
    Range("O1") = "Merchant ID"
    Range("P1") = "Effective Date"
    Range("Q1") = "Co Desc Date"
    Range("R1") = "Elec Trx Code"
    Range("S1") = "Beneficiary"
    Range("T1") = "Trx Type"
    Range("U1") = "Account"
    Range("V1") = "Short MS Co Code"
    Range("W1") = "Pos/Neg"
    Range("X1") = "Sum Cat"
    
    '-----------------------------------------------------------------------------------
    'Clean leading garbage off of formerly merged data set
    '-----------------------------------------------------------------------------------
    For i = 1 To 7
    
        Select Case i
            Case 1
                TempText = "SEC:"
            Case 2
                TempText = "ORIG NAME:"
            Case 3
                TempText = "CO. ENTRY DESC:"
            Case 4
                TempText = "RECIP NAME:"
            Case 5
                TempText = "INDIVIDUAL ID:"
            Case 6
                TempText = "EFFECTIVE DATE:"
            Case 7
                TempText = "CO DESCRIPTION DATE:"
        End Select
        
        Range("K1:R" & RowCount).Select
            Selection.Replace _
                What:=TempText, _
                Replacement:="", _
                LookAt:=xlPart, _
                SearchOrder:=xlByRows, _
                MatchCase:=False, _
                SearchFormat:=False, _
                ReplaceFormat:=False
    Next i
    
    '-----------------------------------------------------------------------------------
    'Main data sorting run.
    '-----------------------------------------------------------------------------------
    For i = 2 To RowCount
    
    'If i = 5 Then iWatch = iWatch + 1  '----------------------------------------------------Loop breaker
    
        '-----------------------------------------------------------------------------------
        'Reformat dates
        '-----------------------------------------------------------------------------------
        Range("P" & i) = Trim(Range("P" & i).Text)
        Range("P" & i) = DateValue(Mid(Range("P" & i).Text, 3, 2) & "-" & Right(Range("P" & i).Text, 2) & "-" & Left(Range("P" & i).Text, 2))
        Range("Q" & i) = Trim(Range("Q" & i).Text)
        Range("Q" & i) = DateValue(Mid(Range("Q" & i).Text, 3, 2) & "-" & Right(Range("Q" & i).Text, 2) & "-" & Left(Range("Q" & i).Text, 2))
    
        '-----------------------------------------------------------------------------------
        'Select BAI Code Description for Case Statement
        '-----------------------------------------------------------------------------------
        Select Case UCase(Trim(Range("F" & i).Text))
    
            '--------------------------------------International Wires
            Case UCase("Individual International Money Transfer Debits"), UCase("Individual International Money Transfer Credits")
                Range("R" & i) = Trim(Range("L" & i).Text)
                Range("S" & i) = Trim(Right(Range("P" & i).Text, Len(Range("P" & i).Text) - 10))
                Range("K" & i & ":Q" & i).ClearContents
                Range("T" & i & ":Z" & i).ClearContents
                Range("T" & i) = "WIR"
                Range("X" & i) = "Trx-Out"
    
                TmpBnkAcct = Range("B" & i).Value
                CoFromBnkAcct
                Range("N" & i) = TmpCoName
           
            '--------------------------------------Domestic Wires
            Case UCase("Outgoing Money Transfer")
                Range("R" & i) = Trim(Range("K" & i).Text)
                Range("S" & i) = Trim(Right(Range("O" & i).Text, Len(Range("O" & i).Text) - 10))
                Range("K" & i & ":Q" & i).ClearContents
                Range("T" & i & ":Z" & i).ClearContents
                Range("T" & i) = "WIR"
                Range("X" & i) = "Trx-Out"
    
                TmpBnkAcct = Range("B" & i).Value
                CoFromBnkAcct
                Range("N" & i) = TmpCoName
    
            '--------------------------------------Incoming Wires
            Case UCase("Incoming Money Transfer")
                Range("R" & i) = Trim(Range("K" & i).Text)
                Range("S" & i) = Trim(Right(Range("O" & i).Text, Len(Range("O" & i).Text) - 5))
                Range("K" & i & ":Q" & i).ClearContents
                Range("T" & i & ":Z" & i).ClearContents
                Range("T" & i) = "WIR"
                Range("X" & i) = "Trx-In"
            
                TmpBnkAcct = Range("B" & i).Value
                CoFromBnkAcct
                Range("N" & i) = TmpCoName
    
            '--------------------------------------Physical Check Deposits
            Case UCase("Check Deposit Package")
                Range("R" & i) = Trim(Range("K" & i).Text)
                Range("S" & i) = Trim(Right(Range("O" & i).Text, Len(Range("O" & i).Text) - 10))
                Range("K" & i & ":Q" & i).ClearContents
                Range("T" & i & ":Z" & i).ClearContents
                Range("T" & i) = "DEP"
                Range("X" & i) = "Chk-Dep"
    
                TmpBnkAcct = Range("B" & i).Value
                CoFromBnkAcct
                Range("N" & i) = TmpCoName
    
            '--------------------------------------Credit Card Transactions & Some Other Stuff
            Case UCase("PREAUTHORIZED ACH Credit"), UCase("PREAUTHORIZED ACH Debit"), UCase("ACH DEBIT RECEIVED")
            
                '--------------------------------------Credit Card Transactions
                If Range("B" & i).Value = "1330242014" Then
                    Range("K" & i) = Trim(Range("K" & i).Text)
                    Range("L" & i) = Trim(Range("L" & i).Text)
                    Range("M" & i) = Trim(Range("M" & i).Text)
                    Range("N" & i) = Trim(Range("N" & i).Text)
                    If IsNumeric(Range("O" & i).Value) Then Range("O" & i) = "'" & Range("O" & i).Value
                    If Not IsNumeric(Range("O" & i).Value) Then Range("O" & i) = Trim(Range("O" & i).Text)
    '                Range("P" & i) = Trim(Range("P" & i).Text)
    '                Range("P" & i) = DateValue(Mid(Range("P" & i).Text, 3, 2) & "-" & Right(Range("P" & i).Text, 2) & "-" & Left(Range("P" & i).Text, 2))
    '                Range("Q" & i) = Trim(Range("Q" & i).Text)
    '                Range("Q" & i) = DateValue(Mid(Range("Q" & i).Text, 3, 2) & "-" & Right(Range("Q" & i).Text, 2) & "-" & Left(Range("Q" & i).Text, 2))
        
                    '--------------------------------------Add Trx Type (Used for Credit Cards)
                    Range("T" & i) = "TRX"
                    If Left(Range("F" & i).Text, 3) = "ZBA" Then
                        Range("T" & i) = "ZBA"
                        Range("U" & i) = "10023-000-00"
                      
                    Else
                        Select Case Range("M" & i).Text
                            Case "AXP DISCNT", "INTERCHNG", "DISCOUNT", "FEE", "BILLING"
                                Range("T" & i) = "FEE"
                            Case "CHARGEBACK", "CHGBK REV", "CHGBCK/ADJ"
                                Range("T" & i) = "CBK"
                            Case "COLLECTION"
                                Range("T" & i) = "CBK"
                        End Select
                    End If
                    
                    'This is to capture the one tiny oddball Amex fee that is not marked correctly.
                    If Range("M" & i).Text = "COLLECTION" And (Range("O" & i).Text = "2280654088" Or Right(Range("N" & i).Text, 10) = "2280654088") Then Range("T" & i) = "FEE"
        
                    '--------------------------------------Bank of America (Visa/MC/Discover) - Oh, and now the AUTHNET fees too.
                    TempNo = Range("O" & i).Text
                    If IsNumeric(TempNo) Then GoTo 1001 'If BofA, skip past Amex/PayPal
                    
                    '--------------------------------------American Express
                    TempNo = Right(Range("N" & i).Text, 10)
                    If IsNumeric(TempNo) Then GoTo 1001 'If Amex, skip past PayPal
                    
                    '--------------------------------------PayPal
                    If Left(Range("L" & i).Text, 6) = "PAYPAL" Then
                        
                        TempNo = Trim(Range("O" & i).Text)
                        Range("N" & i) = "MS Inc"
                        If IsNumeric(TempNo) Then Range("O" & i) = "'" & TempNo
                        If Not IsNumeric(TempNo) Then Range("O" & i) = TempNo
                        Range("T" & i) = "PPL"
                        Range("U" & i) = "10080-000-00"
                
                    End If
                    
                    GoTo 2001 'If it was paypal, this skips past the BofA and Amex processing.
1001:
                    '--------------------------------------Assign Company Info Based on Merchant Account Number
                    Select Case TempNo
                        Case "345819910885", "2040462459", "93956262", "100368703", "243160900888", "100627758"
                            Range("N" & i) = "CA Inc - Irvine"
                            TempText = "-030-02"
                        Case "345819911883", "2040461444", "93955052", "100386461", "243160902884", "100627551"
                            Range("N" & i) = "NY Inc - Farmingdale"
                            TempText = "-030-01"
                        Case "345819912881", "2543533798", "100373014", "243160901886", "100701860"
                            Range("N" & i) = "NY Inc - Farmingdale"
                            TempText = "-090-00"
                        Case "372354350889", "1053341830", "93997948", "243203056888", "100267122", "100703377"
                            Range("N" & i) = "CO Inc - Greenwood Village"
                            TempText = "-040-01"
                        Case "345565540886", "2201812054", "93931416", "100374006", "243203054883", "100743189"
                            Range("N" & i) = "MA Inc - Norwood"
                            TempText = "-020-00"
                        Case "372354349881", "2280654088", "100266046", "243203050881", "100742250"
                            Range("N" & i) = "NH Inc - Derry"
                            TempText = "-070-00"
                        Case "345565541884", "2292593456", "93900228", "100414318", "243203058884", "100764029"
                            Range("N" & i) = "NJ Inc - Woodbridge"
                            TempText = "-001-00"
                        Case "372616410885", "4423101047", "100406300", "243203055880", "100701763"
                            Range("N" & i) = "TX Inc - Allen"
                            TempText = "-050-00"
                        Case "345819936880", "1049181217", "93931417", "100374008", "243160911885", "100743193"
                            Range("N" & i) = "MS Inc - Manual Transactions"
                            TempText = "-000-00"
                        Case "345819933887", "1043028521", "93900226", "100414320", "243160910887", "100806336"
                            Range("N" & i) = "MS Inc - BaseballMonkey.com"
                            TempText = "-000-00"
                        Case "345819930883", "1043747401", "93900259", "100384901", "243160914889", "100763852"
                            Range("N" & i) = "MS Inc - GoalieMonkey.com"
                            TempText = "-000-00"
                        Case "345819932889", "5047624267", "93805481", "100366841", "243160913881", "100742337"
                            Range("N" & i) = "MS Inc - HockeyMonkey.com"
                            TempText = "-000-00"
                        Case "345819931881", "5040633901", "93804115", "243160912883", "100189376", "100775814"
                            Range("N" & i) = "MS Inc - LacrosseMonkey.com"
                            TempText = "-000-00"
                        Case "345819938886", "3042827329", "94033238"
                            Range("N" & i) = "MS Inc - Monkey Apparel"
                            TempText = "-000-00"
                        Case "345819935882", "1043747427", "243160915886"
                            Range("N" & i) = "MS Inc - Team Sales (Yahoo)"
                            TempText = "-000-00"
                        Case "345819934885", "93805556", "100443774", "243203057886", "100742943"
                            Range("N" & i) = "MS Inc - Team Sales (Authorize.net)"
                            TempText = "-000-00"
                        Case "345819937888"
                            Range("N" & i) = "MS Inc - Square Gadget"
                            TempText = "-000-00"
        
                    End Select
                    
                    '--------------------------------------Assign GL Account Number Based on Trx Type
                    If Range("T" & i) = "TRX" Then Range("U" & i) = "10085" & TempText
                    If Range("T" & i) = "FEE" Then Range("U" & i) = "60038" & TempText
                    If Range("T" & i) = "CBK" Then Range("U" & i) = "41200" & TempText
    
2001:
                    '--------------------------------------Assign GL Account Number Based on Trx Type
                    If Range("G" & i).Value >= 0 Then Range("X" & i) = "CC-Pos"
                    If Range("G" & i).Value < 0 Then Range("X" & i) = "CC-Neg"
    
                
                '--------------------------------------ABL Transactions
                ElseIf Trim(Range("M" & i).Text) = "ABL Trans" Then
                    Range("S" & i) = Range("L" & i).Text
                    Range("K" & i) = Trim(Range("M" & i).Text) & " - " & Trim(Range("O" & i).Text)
                    Range("L" & i & ":O" & i).ClearContents
                    Range("T" & i) = "ACH"
                    Range("X" & i) = "ABL-Trx"
                    
                    TmpBnkAcct = Range("B" & i).Value
                    CoFromBnkAcct
                    Range("N" & i) = TmpCoName
                
                '--------------------------------------Collateral Account Transactions
                ElseIf Range("B" & i).Value = "1330244661" And Left(Range("L" & i).Text, 3) <> "DLX" Then
                    Range("T" & i & ":X" & i).ClearContents
                    Range("N" & i) = "MS Inc"
                    Range("T" & i) = "COL"
                    Range("X" & i) = "Collateral"
                    
                    TmpBnkAcct = Range("B" & i).Value
                    CoFromBnkAcct
                    Range("N" & i) = TmpCoName
    
                '--------------------------------------Everything Else - Looks like outgoing ACH transactions.
                Else
    
                    Range("S" & i) = Range("L" & i).Text
                    Range("K" & i) = Trim(Range("M" & i).Text) & " - " & Trim(Range("O" & i).Text)
                    Range("L" & i & ":O" & i).ClearContents
                    Range("T" & i) = "ACH"
                    Range("X" & i) = "Trx-Out"
                    
                    TmpBnkAcct = Range("B" & i).Value
                    CoFromBnkAcct
                    Range("N" & i) = TmpCoName
                    
                End If
                
                If Left(Range("Q" & i).Text, 7) = "ADDENDA" Then Range("Q" & i) = ""
                If Left(Range("R" & i).Text, 7) = "ADDENDA" Then Range("R" & i) = ""
                
            '--------------------------------------Checks
            Case UCase("Check Paid")
                Range("T" & i) = "CHK"
                Range("X" & i) = "Check"
                
                TmpBnkAcct = Range("B" & i).Value
                CoFromBnkAcct
                Range("N" & i) = TmpCoName
            
            '--------------------------------------ZBA - Disregarded, but not deleted.
            Case UCase("ZBA Debit"), UCase("ZBA Credit"), UCase("ZBA Debit Transfer"), UCase("ZBA Credit Transfer")
                Range("T" & i) = "ZBA"
                Range("X" & i) = "ZBA"
                Range("L" & i) = Right(Range("H" & i).Text,9)
                
                TmpBnkAcct = Range("B" & i).Value
                CoFromBnkAcct
                Range("N" & i) = TmpCoName
            
            '--------------------------------------Misc Fees, Debits, and Credits
            Case UCase("Miscellaneous Credit"), UCase("Miscellaneous Debit"), UCase("Miscellaneous Fees"), UCase("Account Analysis Fee")
                If Range("F" & i).Text = UCase("Account Analysis Fee") Then
                    Range("T" & i) = ""
                    Range("X" & i) = "Bnk-Fee"
                End If
                    
                If Range("F" & i).Text = UCase("Miscellaneous Debit") Then
                    Range("T" & i) = ""
                    Range("X" & i) = "Trx-Out"
                    If Left(Range("K" & i).Text, 18) = "ONLINE TRANSFER-TO" Then Range("K" & i) = "Trx To " & Mid(Range("K" & i).Text, 29, 10)
                    If Left(Range("K" & i).Text, 5) = "SWEEP" Then
                        Range("T" & i) = ""
                        Range("X" & i) = "ABL-Trx"
                    End If
                End If
                
                If Range("F" & i).Text = UCase("Miscellaneous Credit") Then
                    If Left(Range("K" & i).Text, 5) = "SWEEP" Or Left(Range("K" & i).Text, 11) = "CREDIT MEMO" Then
                        Range("T" & i) = ""
                        Range("X" & i) = "ABL-Trx"
                    Else
                        Range("T" & i) = ""
                        Range("X" & i) = "Trx-In"
                    End If
                    If Left(Range("K" & i).Text, 18) = "ONLINE TRANSFER-FR" Then Range("K" & i) = "Trx Fr " & Mid(Range("K" & i).Text, 31, 10)
                End If
                
                TmpBnkAcct = Range("B" & i).Value
                CoFromBnkAcct
                Range("N" & i) = TmpCoName
            
            '--------------------------------------Other stuff - this will flag if something didn't fall in a bucket.
            Case Else
                Range("T" & i) = "Case Not Found"
                Range("X" & i) = "Case Not Found"
                TmpBnkAcct = Range("B" & i).Value
                CoFromBnkAcct
                Range("N" & i) = TmpCoName
                
        End Select
    
        '--------------------------------------Short Name
        If Len(Range("N" & i).Text) >= 6 _
        Then Range("V" & i) = Left(Range("N" & i).Text, 6)
             
        '--------------------------------------Payroll Marker
        If Range("K" & i).Text Like "*CLIENT AC*" Then
            Range("T" & i) = "PRL"
            Range("X" & i) = "Prl"
        End If
        
        'apply entry description column to blank description column
        If IsEmpty(Range("M" & i)) Or Range("M" & i).Value = "" Then
            Range("M" & i).Value = Range("K" & i).Value
        End If
        Dim rawText As String
        Dim cleanedText As String
        Dim onlyNumbers As String
        Dim onlyLetters As String
        Dim ch As String * 1
        Dim j As Long
        If Range("M" & i).Text Like "*FRST BK MRCH SVCCHARGEBACK*" or  Range("M" & i).Text Like "*FRST BK MRCH SVCDEPOSIT*" 
        or Range("F" & i).Text Like "*ZBA*" Then


            rawText = Trim(Range("M" & i).Value)

            '--- INSERT SPACE IF LETTER → NUMBER TRANSITION HAS NO SPACE ---
            cleanedText = ""
            For j = 1 To Len(rawText) - 1
                ch = Mid(rawText, j, 1)

                cleanedText = cleanedText & ch

                'If current char is a letter and next char is a number → insert space
                If ch Like "[A-Za-z]" And Mid(rawText, j + 1, 1) Like "[0-9]" Then
                    cleanedText = cleanedText & " "
                End If
            Next j

            'Add last character
            cleanedText = cleanedText & Right(rawText, 1)

            'Re-trim final string
            cleanedText = Trim(cleanedText)

            '--- NOW SPLIT INTO TEXT VS NUMBERS ---
            onlyNumbers = ""
            onlyLetters = ""

            For j = 1 To Len(cleanedText)
                ch = Mid(cleanedText, j, 1)
                
                If ch Like "[0-9]" Then
                    onlyNumbers = onlyNumbers & ch
                Else
                    onlyLetters = onlyLetters & ch
                End If
            Next j

            onlyLetters = WorksheetFunction.Trim(onlyLetters)

            '--- OUTPUT ---
            If Range("F" & i).Text Like "*ZBA*" Then
                Range("K" & i).Value = "ZBA"
                Range("L" & i).Value = Right(onlyNumbers, 9)
            Else
                Range("K" & i).Value = onlyLetters
                Range("L" & i).Value = Right(onlyNumbers, 12)
                Range("M" & i).Value = onlyLetters &" " & onlyNumbers
            End If
        End If

        If IsEmpty(Range("L" & i)) Or Trim(Range("L" & i).Value) = "" Then
        'keep all the processor column values if the column is not empty
            If Range("B" & i).Text = "980094315" And (Range("F" & i).Text = "ELECTRONIC DEBIT" Or Range("F" & i).Value = "ACH CREDIT RECEIVED") Then
            'if account # is 980094315 or the BIA code are the following, preform the rest of the conditionals
                amex_express_settlement_desc = "AMERICAN EXPRESSSETTLEMENT" 'setting this as description value for the 980094315 account
                If Range("M" & i).Text Like "*AMERICAN EXPRESSSETTLEMENT*" Then
                Range("K" & i).Value = amex_express_settlement_desc
                parse_word = Right(Range("M" & i).Value, Len(Range("M" & i)) - 32) 'take out the last word from this desc
                Range("L" & i).Value = UCase(Left(parse_word, 1)) & LCase(Right(parse_word, Len(parse_word) - 1))
                '^Take the last word in Amex settlement. Ex Hockey, Lacross, HomeRun etc. 
                Range("K" & i).Value = "AMERICAN EXPRESSSETTLEMENT" 'set description column value to amex settlement
                ElseIf Range("M" & i).Text Like "*Adyen*" Then
                    Range("L" & i).Value = "Adyen"
                'If word Aiden in Entry description column, make processor column = Adyen
                
                End If
                If Range("M" & i).Text Like "*AMERICAN EXPRESSCHGBCK*" Then 'everything with chgbck entry desc will put the regular description as this value
                Range("M" & i).Value = "AMERICAN EXPRESSCHGBCK"
                ElseIf Range("M" & i).text like "*AUTHNET GATEWAY BILLING*" Then
                Range("K" & i).value = "AUTHNET GATEWAY BILLING"
                ElseIf Range("M" & i).Text Like "*HOCKEY*" Then
                Range("L" & i).Value = "Hockey"
                Range("M" & i).Value = amex_express_settlement_desc
                ElseIf Range("M" & i).Text Like "*GOALIE*" Then
                Range("L" & i).Value = "Goalie"
                Range("M" & i).Value = amex_express_settlement_desc
                ElseIf Range("M" & i).Text Like "*MANUAL TRA*" Then
                Range("L" & i).Value = "Manual Transfer"
                Range("M" & i).Value = amex_express_settlement_desc
                ElseIf Range("M" & i).Text Like "*HOMERUN*" Then
                Range("L" & i).Value = "Homerun"
                Range("M" & i).Value = amex_express_settlement_desc
                ElseIf Range("M" & i).Text Like "*LACROSSE*" Then
                Range("L" & i).Value = "Lacrosse"
                Range("M" & i).Value = amex_express_settlement_desc
                End If

                
            End If
        ElseIf Range("M" & i).Text Like "*PAYPAL*" Then
            Range("L" & i).Value = "Paypal"
            Range("K" & i).Value = "Paypal"
            'If processor column equals PAYPAL, set the Entry Desc Column to concat of Processor col and Entry Desc (Col M & L)
            'ex. final column will be somethign like PAYPAL TRANSFER 2510271045738054706
        ElseIf Range("L" & i).Text ="PAYOUT" Then
            Range("K" & i).Value = "Ayden Inc"
            Range("L" & i).value = "Ayden"
            'final form will be something like Adyen Inc  PAYOUT  250102TX47089501800XT
        End If
        
        'If the processor cell has a number that equals 18 characters, create a new column for the entry desc and  update the processor column
        If Len(Range("L" & i).Value) = 18 Then
            Range("M" & i).Value = Range("M" & i).Text & "  " & Range("L" & i).Text
            Range("L" & i).Value = Right(Range("L" & i).Text, 12)
        End If

            
        If IsEmpty(Range("L" & i)) Or Trim(Range("L" & i).Value) = "" Then
        'check processor column to see if it's blank
            If InStr(1, Range("F" & i).Value, "ZBA", vbTextCompare) > 0 Then
            'check if the BIA description zolumn contains ZBA,
                Range("L" & i).Value = Right(Range("B" & i).Text, 9)
            'if it does, add the last 9 digists of the account number
            End If
        End If
        
    Next i
    
    Final_Format
    
    Application.ScreenUpdating = True
    
    
End Sub