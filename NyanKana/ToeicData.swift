import Foundation

/// Original TOEIC-style listening & reading material (written for Nyanglish).
/// Part 2: speaker|question|A|B|C|answer index|ja tip|tag
/// Part 3/4/6/7: blocks separated by "---". Lines: "M:/W:/N:" spoken lines (3/4), "P:" passage lines (6/7),
/// "Q:" question|choice A|B|C|D|answer index|ja tip|tag
enum ToeicData {
    static let part2 = """
W|Where is the staff meeting being held?|In Conference Room B.|At three o'clock.|Yes, I held it yesterday.|0|Where（どこ）には場所で答える。時刻や Yes/No は不正解。|wh
M|When will the new printer arrive?|It prints in color.|Sometime next Tuesday.|At the supply store.|1|When（いつ）には時を答える。print の音のひっかけに注意。|wh
W|Who's in charge of the Lee account?|Ms. Park handles it.|About two hundred dollars.|I'll charge it to my card.|0|Who（だれ）には人を答える。charge の別の意味のひっかけ。|wh
M|Why was the flight delayed?|Because of the heavy snow.|Gate twelve, I think.|It's a direct flight.|0|Why には Because や理由で答える。|wh
W|How do I get to the train station?|Take the number five bus.|It's very well trained.|About ten minutes ago.|0|How（どうやって）には方法を答える。train/trained の音に注意。|wh
M|How long will the renovation take?|About three weeks.|It's quite long.|The new lobby.|0|How long には期間で答える。|wh
W|Which hotel did you book for the conference?|The one near the convention center.|Yes, I read the book.|For four nights.|0|Which（どれ）には「the one ~」で答えることが多い。|wh
M|What time does the store open on Sundays?|At ten in the morning.|It's on Main Street.|They sell office supplies.|0|What time には時刻で答える。|wh
W|Where should I put these boxes?|Next to the copy machine, please.|Yes, they're quite heavy.|I'll put on my coat.|0|場所を答えている選択肢が正解。put の繰り返しはひっかけ。|wh
M|Who will lead the training session?|Mr. Ito from the sales team.|It starts at nine.|In the main hall.|0|人物を答えている A が正解。|wh
W|Haven't you finished the budget report yet?|I'm almost done.|It's on a tight budget.|Yes, the report says so.|0|否定疑問文でも「終わった？」と同じ意味。進み具合で答える。|yesno
M|Is the cafeteria open during the holiday?|No, it's closed until Monday.|I'd like a sandwich.|It's on the first floor.|0|Is ~? に No と状況を加えて答えている。|yesno
W|Did you send the invoice to the client?|I'll do it right after lunch.|The client is very happy.|It costs five dollars.|0|Yes/No を言わずに「これからやる」と答える型に注意。|yesno
M|Can you help me set up the projector?|Sure, give me a minute.|The project is on schedule.|It's a new set.|0|依頼の Can you ~? には Sure / Of course が定番。|request
W|Could you email me the agenda?|I'll send it right away.|The agenda was long.|She's not here today.|0|依頼に対して「すぐ送ります」と応じている。|request
M|Would you like some coffee before the meeting?|Thanks, that would be great.|The meeting room is upstairs.|I like the new design.|0|Would you like ~?（申し出）には Thanks / No, thanks。|request
W|Why don't we take a short break?|Good idea, I'm a little tired.|Because it broke down.|It took two hours.|0|Why don't we ~? は理由ではなく提案。賛成・反対で答える。|suggest
M|Let's order lunch for the team.|Sounds good. What should we get?|The order was shipped.|A team of five people.|0|Let's ~ の提案に「いいね」と応じる。|suggest
W|Should we hire a temporary worker or ask the current staff to work overtime?|Hiring someone would be better.|Yes, we should.|For two weeks.|0|A or B の選択疑問文には Yes/No で答えない。|choice
M|Do you want to meet on Monday or Tuesday?|Tuesday works better for me.|Yes, I do.|It was a long meeting.|0|選択疑問文。どちらかを選ぶか、別の案を出す。|choice
W|The elevator is out of order again.|I'll call the maintenance office.|On the third floor.|In alphabetical order.|0|平叙文（報告）には対応や感想で応じる。order の多義に注意。|statement
M|I can't find my security badge.|Did you check your desk drawer?|The badge is blue.|Security is very important.|0|困りごとの報告に助言・質問で返す型。|statement
W|You attended the trade show last week, didn't you?|Yes, it was very crowded.|Trade is increasing.|Next week, I hope.|0|付加疑問文は普通の Yes/No 疑問文と同じように答える。|yesno
M|How much does the annual membership cost?|It's sixty dollars a year.|Every year in May.|Quite a lot of members.|0|How much には金額で答える。|wh
W|Whose turn is it to clean the break room?|I think it's Mark's.|Turn left at the corner.|It's very clean now.|0|Whose（だれの）には人を答える。turn の多義に注意。|wh
M|Where can I find the latest sales figures?|They're on the shared drive.|Sales went up this month.|I'm still looking.|0|Where に「どこにあるか」を答えている。|wh
W|When is the deadline for the proposal?|By the end of this week.|It's a strong proposal.|Mr. Chen wrote it.|0|期限を答えている A が正解。|wh
M|Who should I talk to about my vacation request?|Your department manager.|To Hawaii, probably.|It's been approved.|0|Who に役職で答えるのもよくある正解。|wh
W|Do you know where the nearest pharmacy is?|There's one across the street.|Yes, I know him well.|It's open until nine.|0|間接疑問文 Do you know where ~? は「場所」を答える。|yesno
M|I'd like to change my reservation to Friday.|Let me check if a room is available.|It's a nice change.|On Thursday evening.|0|依頼・要望に対して対応を始める応答。|request
"""

    static let part3 = """
W: Hi, I'm calling about the printer I ordered last week. It was supposed to arrive on Monday, but I still haven't received it.
M: I'm sorry about that. Let me check the order. Can you give me your order number?
W: Sure, it's 4-5-7-2-1.
M: I see. It looks like the shipment was sent to our old warehouse by mistake. I'll have it delivered to you by express tomorrow, at no extra charge.
Q: Why is the woman calling?|To order a new printer|To report a missing delivery|To ask for a repair|To cancel a reservation|1|「まだ届いていない」と言っている。電話の目的は冒頭に出やすい。|gist
Q: What does the man ask the woman for?|Her address|Her phone number|An order number|A receipt|2|Can you give me your order number? と聞いている。|detail
Q: What does the man offer to do?|Give a refund|Send the item by express|Visit her office|Lower the price|1|express で明日届ける、追加料金なしと言っている。|detail
---
M: Linda, have you finished the slides for Thursday's client presentation?
W: Almost. I just need the sales figures from the second quarter. The finance department hasn't sent them yet.
M: I can call Daniel in finance. He usually responds quickly.
W: That would be great. Then I can finish the slides this afternoon.
Q: What are the speakers preparing for?|A job interview|A client presentation|A training session|A product launch|1|Thursday's client presentation と言っている。|gist
Q: What is the woman waiting for?|Sales figures|A new laptop|Approval from a manager|A meeting room|0|sales figures from the second quarter を待っている。|detail
Q: What will the man probably do next?|Finish the slides|Call someone in finance|Cancel the meeting|Email the client|1|I can call Daniel in finance と申し出ている。次の行動は後半に出る。|next
---
W: Welcome to Greenfield Hotel. How can I help you?
M: I have a reservation under the name Kenji Sato. I'm checking in for three nights.
W: Yes, Mr. Sato. Your room is on the twelfth floor. Breakfast is served from six thirty to ten in the restaurant on the second floor.
M: Great. Also, is there a place where I can print some documents?
W: Yes, our business center is next to the lobby. It's open twenty-four hours.
Q: Where does the conversation take place?|At an airport|At a hotel|At a restaurant|At a print shop|1|Welcome to Greenfield Hotel / checking in から場所がわかる。|gist
Q: How long will the man stay?|One night|Two nights|Three nights|A week|2|three nights と言っている。|detail
Q: Where is the business center?|On the second floor|On the twelfth floor|Next to the lobby|In the restaurant|2|next to the lobby（ロビーの隣）と言っている。数字のひっかけに注意。|detail
---
M: Did you hear that the company is moving to a new office building next spring?
W: Yes, I heard it's downtown, near the central station. That will make my commute much shorter.
M: Lucky you. I live in the suburbs, so it'll take me longer. I might start taking the train instead of driving.
W: The new building also has a gym on the ground floor, so that's a nice bonus.
Q: What are the speakers mainly discussing?|A new office location|A train schedule|A gym membership|A company merger|0|会社の移転について話している。|gist
Q: What does the woman say about her commute?|It will be longer.|It will be shorter.|It will be more expensive.|It will not change.|1|much shorter と言っている。|detail
Q: What does the man say he might do?|Move to the suburbs|Join a gym|Take the train|Buy a new car|2|I might start taking the train と言っている。|next
---
W: Excuse me, I bought this jacket here yesterday, but it's a little too small. Can I exchange it for a larger size?
M: Of course. Do you have your receipt?
W: Yes, here it is.
M: Thank you. Hmm, it looks like we're out of the large size in blue. Would you like it in black, or should I order a blue one for you? It would take about five days.
W: I'll take the black one, then. I'd like to wear it this weekend.
Q: What does the woman want to do?|Return a jacket for a refund|Exchange a jacket|Buy a gift|Order a new color|1|exchange it for a larger size と言っている。|gist
Q: What problem does the man mention?|The receipt is missing.|The store is closing.|A size is out of stock.|The price has changed.|2|we're out of the large size in blue（青のLサイズは品切れ）と言っている。|detail
Q: Why does the woman choose the black jacket?|It is cheaper.|She wants to wear it soon.|She prefers the color.|The blue one is damaged.|1|this weekend に着たいので待てない、という意図。|inference
---
M: Hi, Rachel. I'm organizing the team dinner for Friday. Would Italian food be okay with everyone?
W: I think so, but remember that Tom doesn't eat meat.
M: Good point. The restaurant I'm thinking of has plenty of vegetarian dishes.
W: Then it should be fine. Should I send a message to the team to confirm the time?
M: Yes, please. Let's say seven o'clock.
Q: What is the man organizing?|A business trip|A team dinner|A cooking class|A client meeting|1|team dinner for Friday と言っている。|gist
Q: What does the woman remind the man about?|The restaurant is far.|A coworker does not eat meat.|Friday is a holiday.|The budget is small.|1|Tom doesn't eat meat（トムは肉を食べない）と言っている。|detail
Q: What will the woman do?|Book the restaurant|Cook vegetarian dishes|Contact the team|Change the date|2|send a message to the team と申し出て、Yes, please と頼まれている。|next
---
W: The new accounting software was installed over the weekend. Have you had a chance to try it?
M: I logged in this morning, but I couldn't find where to enter my travel expenses.
W: It's under the "Reports" tab now, not "Expenses." It confused me too at first.
M: Oh, thanks. Is there a manual somewhere?
W: The IT team is holding a short training session on Wednesday at two. You should sign up.
Q: What problem does the man have?|He forgot his password.|He cannot find a feature.|His computer is broken.|He missed a deadline.|1|couldn't find where to enter my travel expenses（交通費をどこに入力するかわからなかった）と言っている。|detail
Q: Where can the man enter his travel expenses?|Under the Reports tab|Under the Expenses tab|In a paper form|On the IT website|0|It's under the "Reports" tab now（今は「Reports」タブの中にある）と答えている。|detail
Q: What does the woman suggest?|Calling the IT team|Reading the manual|Attending a training session|Using the old software|2|You should sign up（研修への参加）を勧めている。|suggest
---
M: Thank you for coming in today. We were impressed by your résumé, especially your experience in marketing.
W: Thank you. I've worked in digital marketing for five years, mostly on social media campaigns.
M: That's exactly what we need. This position would involve managing our online advertising. When would you be able to start?
W: I need to give my current employer two weeks' notice, so I could start at the beginning of next month.
Q: What is the purpose of the conversation?|A job interview|A sales meeting|A product review|A training course|0|résumé / position / start などから面接だとわかる。|gist
Q: How long has the woman worked in digital marketing?|Two years|Three years|Five years|Ten years|2|five years と言っている。|detail
Q: Why can't the woman start immediately?|She is moving.|She must give notice to her employer.|She is on vacation.|She needs training.|1|two weeks' notice が必要と言っている。|inference
---
W: Hello, this is Mia from Bright Design. We sent you the logo samples yesterday. Did you have a chance to look at them?
M: Yes, thank you. We like the second design, but could you make the letters a little bigger?
W: Of course. Would you also like to try a different color?
M: Hmm, I'll have to check with my manager first. Can I get back to you tomorrow?
W: Sure. I'll start on the letter size in the meantime.
Q: What does the man like?|The first design|The second design|The third design|None of the designs|1|We like the second design（2つ目のデザインが気に入った）と言っている。|detail
Q: What change does the man request?|A different color|Bigger letters|A new shape|A lower price|1|make the letters a little bigger（文字を少し大きく）と頼んでいる。|detail
Q: Why will the man contact the woman tomorrow?|To sign a contract|To check with his manager first|To send a payment|To visit her office|1|check with my manager first と言っている。|inference
"""

    static let part4 = """
N: Attention, passengers. The 3:15 express train to Riverside has been delayed by approximately twenty minutes due to a signal problem. We apologize for the inconvenience. Passengers traveling to Hillcrest may take the local train departing from Platform 4 at 3:20. Further updates will be announced as soon as they are available.
Q: Where is the announcement being made?|At an airport|At a train station|On a bus|In a shopping mall|1|passengers / train / Platform から駅だとわかる。|gist
Q: What caused the delay?|Bad weather|A signal problem|An accident|A staff shortage|1|due to a signal problem（信号トラブルのため）と言っている。|detail
Q: What are passengers to Hillcrest advised to do?|Wait for an update|Take a local train|Take a bus|Get a refund|1|local train ... from Platform 4（各駅停車は4番線から）と案内している。|detail
---
N: Hello, Ms. Rivera. This is Paul from Sunrise Dental Clinic, calling to remind you of your appointment tomorrow, Thursday, at ten A.M. Please arrive about ten minutes early to fill out a short form. If you need to change the time, please call us at 555-0142 before five o'clock today. Thank you, and see you tomorrow.
Q: Why is the speaker calling?|To cancel an appointment|To remind a patient of an appointment|To ask for a payment|To introduce a new doctor|1|calling to remind you of your appointment（予約の確認の電話）とあるので、目的は予約の確認。|gist
Q: What is the listener asked to do?|Bring an ID card|Arrive early|Call back tomorrow|Pay in advance|1|arrive about ten minutes early と言っている。|detail
Q: By what time should the listener call to change the time?|Ten A.M. tomorrow|Noon today|Five o'clock today|Ten minutes before the appointment|2|before five o'clock today（今日の5時まで）と言っている。|detail
---
N: Good morning, everyone, and welcome to your first day at Northway Electronics. I'm Karen, the human resources manager. This morning, you'll get your ID badges and a tour of the factory. After lunch, which will be served in the cafeteria at noon, you'll meet your team leaders. Please remember that safety glasses must be worn at all times on the factory floor.
Q: Who are the listeners?|New employees|Factory visitors|Team leaders|Customers|0|first day at Northway Electronics → 新入社員。|gist
Q: What will happen after lunch?|A safety test|A factory tour|Meeting team leaders|Receiving ID badges|2|After lunch ... you'll meet your team leaders（昼食後にチームリーダーと会う）。順番に注意。|detail
Q: What must the listeners do on the factory floor?|Wear safety glasses|Carry their ID badges|Stay with a guide|Turn off their phones|0|safety glasses must be worn at all times（保護メガネは常に着用）と言っている。|detail
---
N: Thank you for calling Blue River Bank. Our offices are currently closed. Our regular business hours are Monday through Friday, nine A.M. to five P.M. If you have lost your bank card, please press one to speak to our emergency service, available twenty-four hours a day. For other questions, you can also visit our website, where many services are available online.
Q: What is the purpose of the message?|To announce new business hours|To give information when the bank is closed|To advertise a new card|To confirm a payment|1|Our offices are currently closed（ただいま営業時間外）とあり、営業時間外の案内。|gist
Q: What should a caller do if they have lost a bank card?|Visit the website|Call back on Monday|Press one|Go to a branch|2|lost your bank card, please press one（カードをなくしたら1番）と案内している。|detail
Q: What does the speaker say about the website?|It is being updated.|Many services are available there.|It is open only on weekdays.|It requires a password.|1|many services are available online（多くのサービスはオンラインで使える）と言っている。|detail
---
N: And now for the local business news. Greenleaf Supermarket will open its newest store on Oak Avenue this Saturday. To celebrate, the first one hundred customers will receive a free reusable shopping bag. The store will also feature a large organic food section and a café. Store manager Ben Hall says the company plans to open three more stores in the region next year.
Q: What is the news report mainly about?|A new store opening|A food festival|A company merger|A road closure|0|newest store ... will open this Saturday（新店舗が今週土曜に開店）と言っている。|gist
Q: What will the first one hundred customers receive?|A discount coupon|A free coffee|A shopping bag|A gift card|2|a free reusable shopping bag（無料のエコバッグ）がもらえると言っている。|detail
Q: What does the company plan to do next year?|Close a store|Open more stores|Sell organic food online|Hire a new manager|1|open three more stores in the region next year（来年さらに3店舗を出す）と言っている。|detail
---
N: Before we begin today's workshop, I'd like to go over a few things. The workshop will run until four o'clock, with a fifteen-minute break at two. Handouts are on the table by the door. Also, we've had a change in the schedule: the session on social media marketing has been moved to tomorrow morning, because the speaker's flight was delayed. Now, let's get started.
Q: When is the break?|At noon|At two o'clock|At three o'clock|At four o'clock|1|a fifteen-minute break at two（2時に15分の休憩）と言っている。|detail
Q: Where are the handouts?|On the speaker's desk|By the door|In an email|On the screen|1|on the table by the door（ドアのそばのテーブルの上）と言っている。|detail
Q: Why was a session moved?|The room was not available.|A speaker's flight was delayed.|Too few people signed up.|The equipment broke.|1|because the speaker's flight was delayed（話し手の飛行機が遅れたため）が理由。|detail
---
N: Hi, Tom. This is Sarah from the marketing team. I'm looking at the brochure draft you sent, and it looks great. Just one thing: the phone number on the back page is our old one. Could you replace it with the new number before we send the file to the printer? We need to send it by Friday, so please let me know when it's done. Thanks.
Q: What does the speaker think of the brochure?|It is too long.|It looks great.|It needs new photos.|It is too expensive.|1|it looks great と言っている。|detail
Q: What problem does the speaker mention?|A wrong phone number|A spelling mistake|A missing page|A late payment|0|the phone number ... is our old one。|detail
Q: What does the speaker ask Tom to do?|Call the printer|Send the file today|Update the phone number|Change the design|2|replace it with the new number と頼んでいる。|request
"""

    static let part6 = """
P: To: All Staff
P: From: Facilities Department
P: Subject: Parking Lot Repairs
P: The east parking lot will be closed from June 3 to June 7 ---(1)--- repairs. During this time, employees are asked to use the parking garage on Pine Street. ---(2)---, a free shuttle bus will run every fifteen minutes between the garage and the main entrance. ---(3)--- We apologize for any inconvenience and thank you for your ---(4)---.
Q: (1)|for|at|by|since|0|「〜のために」閉鎖。目的・理由の for。|p6grammar
Q: (2)|However|In addition|Instead|Otherwise|1|駐車場の案内に「さらに」シャトルの情報を足している。|p6context
Q: (3)|Please allow extra time to arrive at work.|The new cafeteria opens next week.|Parking fees will increase in July.|Our company was founded in 1990.|0|空所の前後（移動手段の変更）につながる文を選ぶ。|p6context
Q: (4)|understand|understanding|understood|understandable|1|your の後ろには名詞。understanding（理解）。|p6grammar
---
P: Dear Ms. Kim,
P: Thank you for your order of twenty office chairs. We are writing to let you know that your order has been ---(1)--- and will arrive on Thursday. ---(2)--- Our delivery team will call you about thirty minutes before arrival. If no one is available to receive the items, the team will ---(3)--- the delivery to another day. Please do not hesitate to contact us with any ---(4)---.
P: Sincerely, Office Plus Customer Service
Q: (1)|ship|shipping|shipped|ships|2|has been + 過去分詞（受け身の完了）。|p6grammar
Q: (2)|Assembly instructions are included in each box.|We are hiring new delivery drivers.|Our store will close early on Friday.|The chairs were designed in Italy.|0|配送の流れの話に合う情報を選ぶ。|p6context
Q: (3)|cancel|reschedule|refuse|reduce|1|「別の日に」なので reschedule（予定を変更する）。|p6vocab
Q: (4)|questions|question|questioned|questioning|0|any の後ろの名詞。数えられる名詞は複数形が自然。|p6grammar
---
P: Riverside Library News
P: Starting next month, the library will ---(1)--- its opening hours on weekends. On Saturdays and Sundays, the library will open at nine A.M. instead of ten. This change is a ---(2)--- to many requests from visitors. ---(3)--- In addition, the children's reading room will be renovated in August. During the work, children's books will be ---(4)--- available on the second floor.
Q: (1)|extend|extension|extensive|extensively|0|will の後ろには動詞の原形。|p6grammar
Q: (2)|response|respond|responsive|responded|0|a の後ろに名詞。a response to ~（〜への対応）。|p6grammar
Q: (3)|We hope this will make the library more convenient.|The library was built fifty years ago.|Library cards can be renewed online.|Please return books on time.|0|開館時間の変更の話の締めくくりに合う文。|p6context
Q: (4)|temporarily|permanently|previously|rarely|0|改装の間だけ＝一時的に（temporarily）。|p6vocab
---
P: Job Opening: Customer Service Representative
P: Starlight Travel is looking for a friendly and ---(1)--- customer service representative to join our team. The successful candidate will answer calls and emails from customers and help them ---(2)--- travel plans. At least two years of experience in customer service is ---(3)---. ---(4)--- To apply, please send your résumé to jobs@starlighttravel.com by March 15.
Q: (1)|reliable|reliability|rely|reliably|0|friendly and ___（形容詞を並べる）。|p6grammar
Q: (2)|make|making|made|to making|0|help + 人 + 動詞の原形。|p6grammar
Q: (3)|required|requiring|requirement|require|0|be required（必須である）。|p6grammar
Q: (4)|Knowledge of a second language is a plus.|Our office is closed on holidays.|Travel prices have increased.|The position was filled last week.|0|応募条件の続きに合う文を選ぶ。最後の選択肢は内容と矛盾。|p6context
---
P: Notice to Residents
P: The water supply in the Maple Apartments building will be ---(1)--- off on Tuesday from one P.M. to four P.M. This is necessary to replace old pipes on the third floor. We recommend that residents store some water ---(2)--- this time. ---(3)--- If you have any concerns, please contact the management office, ---(4)--- is open from nine A.M. to six P.M.
Q: (1)|turned|turning|turn|turns|0|be + 過去分詞（受け身）。be turned off。|p6grammar
Q: (2)|before|during|after|since|0|断水の「前に」水をためておく。|p6vocab
Q: (3)|We are sorry for the inconvenience.|The building has a new gym.|Rent is due on the first of the month.|Parking is available nearby.|0|工事の案内に続く自然な一文。|p6context
Q: (4)|which|who|where|what|0|the management office を先行詞とする関係代名詞（, which）。|p6grammar
"""

    static let part7 = """
P: Green Valley Farmers' Market
P: Open every Saturday, 8 A.M. – 1 P.M., from April to October
P: Location: City Park parking lot (Elm Street)
P: Fresh vegetables, fruit, bread, and flowers from more than 40 local farms.
P: New this year: Cooking demonstrations at 10 A.M. by chefs from local restaurants.
P: Bring your own bag and receive a 5% discount at participating stands!
Q: How often is the market held?|Every day|Every weekend day|Once a week|Once a month|2|Every Saturday → 週に1回。|detail
Q: What is new this year?|Flower sales|Cooking demonstrations|A new location|Longer hours|1|New this year: Cooking demonstrations（今年の新しい催しは料理の実演）とある。|detail
Q: How can shoppers get a discount?|By arriving early|By bringing their own bag|By paying in cash|By buying flowers|1|Bring your own bag and receive a 5% discount（マイバッグ持参で5%引き）とある。|detail
---
P: From: Daniel Ortiz
P: To: Emily Chen
P: Subject: Visit next week
P: Hi Emily,
P: Thank you for agreeing to show me around your factory next Wednesday. I will arrive in Osaka on Tuesday evening. Would it be possible to start the tour at ten instead of nine? My hotel is about an hour away from the factory. Also, two members of my team would like to join us. I hope that is not a problem.
P: Best regards, Daniel
Q: Why did Daniel write the e-mail?|To cancel a visit|To change the details of a visit|To book a hotel|To introduce a new product|1|開始時間の変更と人数の追加をお願いしている。|purpose
Q: What does Daniel ask about the tour?|To end it earlier|To start it later|To hold it on Tuesday|To skip the factory|1|start the tour at ten instead of nine（ツアー開始を9時ではなく10時に）と頼んでいる。|detail
Q: What is suggested about Daniel's team?|They have visited before.|More people will come than planned.|They will arrive on Wednesday morning.|They do not speak Japanese.|1|two members ... would like to join（2人が参加したい）→ 予定より人数が増える。|inference
---
P: Notice: Office Supply Orders
P: Starting May 1, all office supply orders must be made through the new online system. Paper order forms will no longer be accepted. Orders placed by noon will be delivered the next business day. For orders over $200, approval from a department manager is required. If you have trouble logging in, contact Jun at extension 214.
Q: What is the main purpose of the notice?|To announce a new ordering procedure|To introduce a new manager|To advertise office supplies|To explain a delivery delay|0|新しいオンライン注文方法の案内。|purpose
Q: What is required for an order of $250?|A paper form|A manager's approval|Payment in advance|A call to Jun|1|over $200（200ドル超）は department manager（部長）の承認が必要。|detail
Q: When will an order placed at 11 A.M. on Monday arrive?|Monday afternoon|Tuesday|Wednesday|Within a week|1|noon までの注文は翌営業日に届く。|inference
---
P: Mountain View Hotel – Guest Reviews
P: "The view from our room was amazing, and the staff were very kind. The only problem was the Wi-Fi, which was slow in the evenings. Breakfast had many choices, especially for vegetarians. We will definitely come back next year." – Laura P.
Q: What did Laura NOT like?|The view|The staff|The Wi-Fi|The breakfast|2|The only problem was the Wi-Fi（問題はWi-Fiだけ）とある。「当てはまらないもの」を選ぶ問題に注意。|detail
Q: The word "definitely" is closest in meaning to|certainly|possibly|rarely|quickly|0|definitely＝きっと、確かに（certainly）。|vocab
---
P: Bayside Fitness – Membership Plans
P: Basic: $30/month. Gym access 6 A.M. – 10 P.M.
P: Plus: $45/month. Gym access 24 hours + group classes.
P: Premium: $60/month. Plus benefits + two personal training sessions per month.
P: Sign up before June 30 and get your first month free!
Q: How much is the plan that includes group classes but no personal training?|$30|$45|$60|Free|1|Plus（$45）が group classes 付き、personal training なし。|detail
Q: What is offered to people who join before June 30?|A free T-shirt|A free first month|A personal trainer|A lower monthly price|1|get your first month free（最初の1か月が無料）とある。|detail
Q: What can Basic members do?|Use the gym at midnight|Join group classes|Use the gym in the morning|Get personal training|2|6 A.M. から使える。24時間は Plus から。|inference
---
P: Text message chain
P: Mika (9:12): Hi Ryan, the client wants to move our meeting from 2 P.M. to 4 P.M. today. Are you free?
P: Ryan (9:15): I have a call at 4, but I can move it. Should I book a meeting room?
P: Mika (9:16): Yes, please. Room C has a projector, so that would be best.
P: Ryan (9:20): Done. Room C at 4.
Q: Why did Mika contact Ryan?|To cancel a meeting|To ask about a time change|To borrow a projector|To introduce a client|1|会議の時間を 2時から4時に変えたいと連絡している。|purpose
Q: At 9:20, what does Ryan mean when he writes, "Done"?|He finished his call.|He booked Room C.|He canceled the meeting.|He sent the slides.|1|直前の「部屋を予約して」への返事。意図問題は前のやりとりを見る。|intent
---
P: Sunshine Café is celebrating its 10th anniversary! From July 1 to July 7, all drinks are half price after 3 P.M. In addition, customers who spend more than $15 will receive a free cookie. Our new summer menu, featuring fresh fruit smoothies, will also be available starting July 1.
Q: What is the advertisement mainly about?|A new café opening|An anniversary event|A cooking contest|A job opening|1|10th anniversary（10周年）を祝うイベント。|purpose
Q: What can customers get at 4 P.M. on July 3?|Free drinks|Half-price drinks|A free smoothie|A gift card|1|after 3 P.M.（午後3時以降）は飲み物が半額。|inference
Q: What is NOT mentioned in the advertisement?|Discounted drinks|A free cookie|New smoothies|Free delivery|3|delivery の話は出てこない。|detail
---
P: Memo
P: To: Sales Team
P: Our quarterly sales meeting will be held on Friday, September 12, in the main conference room. Each team leader should prepare a short report, no longer than ten minutes, about sales in their region. Please send your slides to Ms. Tanaka by Wednesday so that she can combine them into one presentation. Lunch will be provided after the meeting.
Q: What are team leaders asked to do?|Book a conference room|Prepare a short report|Order lunch|Visit their regions|1|Each team leader should prepare a short report（各チームリーダーは短い報告を用意）とある。|detail
Q: By when should the slides be sent?|Monday|Wednesday|Friday|September 12|1|send your slides ... by Wednesday（水曜までにスライドを送る）とある。|detail
Q: Why will Ms. Tanaka receive the slides?|To check the sales numbers|To combine them into one presentation|To print them|To translate them|1|so that she can combine them into one presentation（1つの発表資料にまとめるため）とある。|detail
"""
}
