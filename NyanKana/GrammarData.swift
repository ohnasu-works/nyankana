import Foundation

/// Textbook lessons. One line per grammar point:
/// id | title ja | title ko | title zh | pattern | rule ja (／ = place where a line may break) | rule ko | rule zh
enum GrammarData {
    static let raw = """
be.present|be動詞（〜です）|be동사 (~이다)|be動詞（是）|I am / You are / He is|「AはBです」は／be動詞で／表します。／主語が I なら am、／you や複数なら are、／he・she・it なら is を／使います。|「A는 B이다」는 be동사로 나타냅니다. 주어가 I면 am, you나 복수면 are, he·she·it이면 is를 씁니다.|「A是B」用be動詞表示。主詞是I用am，you或複數用are，he、she、it用is。
be.negative|be動詞の否定文|be동사의 부정문|be動詞的否定句|I am not ~ / He is not ~|「〜ではありません」は／be動詞の／すぐ後ろに／not を置きます。／is not は isn't、／are not は aren't と／短くできます。|「~가 아닙니다」는 be동사 바로 뒤에 not을 둡니다. is not은 isn't, are not은 aren't로 줄일 수 있습니다.|「不是～」在be動詞後面加not。is not可縮寫成isn't，are not可縮寫成aren't。
be.question|be動詞の疑問文|be동사의 의문문|be動詞的疑問句|Are you ~? / Is he ~?|「〜ですか？」は／be動詞を／主語の前に／出します。／答えは Yes, I am. ／No, I'm not. の／ように答えます。|「~입니까?」는 be동사를 주어 앞으로 보냅니다. 대답은 Yes, I am. / No, I'm not. 처럼 합니다.|「是～嗎？」把be動詞移到主詞前面。回答用Yes, I am. / No, I'm not.。
verb.present|一般動詞（現在形）|일반동사 (현재형)|一般動詞（現在式）|I play / You like|play や like など／動作や気持ちを／表す動詞を／一般動詞と／いいます。／習慣や／いつものことを／表します。|play, like처럼 동작이나 감정을 나타내는 동사를 일반동사라고 합니다. 습관이나 평소의 일을 나타냅니다.|play、like等表示動作或心情的動詞叫一般動詞。表示習慣或平常的事。
verb.3s|三人称単数の s|3인칭 단수 s|第三人稱單數加s|He plays / She watches|主語が／he・she・it や／1人の人なら、／動詞に s を／つけます。／watch→watches、／study→studies、／have→has に／注意。|주어가 he·she·it이나 한 사람이면 동사에 s를 붙입니다. watch→watches, study→studies, have→has에 주의하세요.|主詞是he、she、it或單一的人時，動詞加s。注意watch→watches、study→studies、have→has。
verb.neg|一般動詞の否定文|일반동사의 부정문|一般動詞的否定句|I do not play / He does not play|一般動詞の／否定は／動詞の前に／don't を／置きます。／三人称単数なら／doesn't を使い、／動詞は／元の形に／戻します。|일반동사의 부정은 동사 앞에 don't를 둡니다. 3인칭 단수면 doesn't를 쓰고 동사는 원형으로 돌립니다.|一般動詞的否定在動詞前加don't。第三人稱單數用doesn't，動詞恢復原形。
verb.q|一般動詞の疑問文|일반동사의 의문문|一般動詞的疑問句|Do you play ~? / Does he play ~?|疑問文は／文の先頭に／Do（三人称単数は／Does）を／置きます。／動詞は／元の形です。|의문문은 문장 앞에 Do(3인칭 단수는 Does)를 둡니다. 동사는 원형입니다.|疑問句在句首加Do（第三人稱單數用Does），動詞用原形。
past.reg|過去形（規則動詞）|과거형 (규칙동사)|過去式（規則動詞）|played / studied / stopped|過去のことは／動詞に／ed を／つけます。／study→studied、／stop→stopped の／ように／つづりが／変わるものも／あります。|과거의 일은 동사에 ed를 붙입니다. study→studied, stop→stopped처럼 철자가 바뀌는 것도 있습니다.|過去的事在動詞加ed。也有像study→studied、stop→stopped這樣拼法改變的。
past.irr|過去形（不規則動詞）|과거형 (불규칙동사)|過去式（不規則動詞）|go→went / eat→ate / see→saw|ed を／つけずに／形が／変わる動詞が／あります。／よく使う／ものから／一つずつ／覚えましょう。|ed를 붙이지 않고 모양이 바뀌는 동사가 있습니다. 자주 쓰는 것부터 하나씩 외웁시다.|有些動詞不加ed而是改變形態。從常用的開始一個個記住吧。
past.neg|過去の否定文|과거의 부정문|過去式的否定句|I did not go|過去の否定は／didn't を／動詞の前に／置き、／動詞は／元の形に／します。|과거의 부정은 didn't를 동사 앞에 두고 동사는 원형으로 합니다.|過去式的否定在動詞前加didn't，動詞用原形。
past.q|過去の疑問文|과거의 의문문|過去式的疑問句|Did you go ~?|過去の疑問文は／Did を／先頭に／置きます。／動詞は／元の形です。|과거의 의문문은 Did를 문장 앞에 둡니다. 동사는 원형입니다.|過去式的疑問句在句首加Did，動詞用原形。
past.be|be動詞の過去形|be동사의 과거형|be動詞的過去式|I was / You were|be動詞の／過去は／was と were。／I・he・she・it は was、／you と複数は／were を／使います。|be동사의 과거는 was와 were입니다. I·he·she·it는 was, you와 복수는 were를 씁니다.|be動詞的過去式是was和were。I、he、she、it用was，you和複數用were。
prog|進行形|진행형|進行式|I am playing|「今〜しているところ」は／be動詞＋動詞ing で／表します。|「지금 ~하고 있다」는 be동사+동사ing로 나타냅니다.|「正在～」用be動詞＋動詞ing表示。
future.will|未来（will）|미래 (will)|未來式（will）|I will go|「〜するつもり・〜するでしょう」は／will＋動詞の元の形。／その場で／決めたことや／予想に／使います。|「~할 것이다」는 will+동사원형입니다. 그 자리에서 정한 일이나 예상에 씁니다.|「將會～」用will＋原形動詞。用於當場決定的事或預測。
future.going|未来（be going to）|미래 (be going to)|未來式（be going to）|I am going to visit|前から／決めている／予定は／be going to＋動詞の元の形で／表します。|전부터 정해 둔 예정은 be going to+동사원형으로 나타냅니다.|事先決定好的計畫用be going to＋原形動詞表示。
modal.can|can（〜できる）|can (~할 수 있다)|can（能夠）|I can swim|「〜できる」は／can＋動詞の元の形。／Can you 〜? は／「〜してくれる？」という／お願いにも／なります。|「~할 수 있다」는 can+동사원형입니다. Can you ~?는 「~해 줄래?」라는 부탁도 됩니다.|「能夠～」用can＋原形動詞。Can you～?也可以表示請求。
modal.must|must（〜しなければならない）|must (~해야 한다)|must（必須）|You must study / You must not run|「〜しなければならない」は／must。／must not は／「〜してはいけない」という／強い禁止です。|「~해야 한다」는 must입니다. must not은 「~하면 안 된다」는 강한 금지입니다.|「必須～」用must。must not表示「不可以～」的強烈禁止。
modal.may|may（〜してもよい・〜かもしれない）|may (~해도 된다·~일지도 모른다)|may（可以・也許）|May I come in? / It may rain|May I 〜? は／ていねいな／「〜してもいいですか」。／may は／「〜かもしれない」の／意味も／あります。|May I ~?는 정중한 「~해도 될까요?」입니다. may는 「~일지도 모른다」라는 뜻도 있습니다.|May I～?是禮貌的「可以～嗎」。may也有「也許～」的意思。
modal.should|should（〜したほうがよい）|should (~하는 게 좋다)|should（應該）|You should rest|「〜したほうがいい・〜すべき」は／should＋動詞の元の形。／アドバイスで／よく使います。|「~하는 게 좋다·~해야 한다」는 should+동사원형입니다. 조언할 때 자주 씁니다.|「最好～・應該～」用should＋原形動詞，常用於建議。
modal.have|have to（〜しなければならない）|have to (~해야 한다)|have to（不得不）|I have to go / He has to work|have to は／must と／ほぼ同じ意味。／don't have to は／「〜しなくてよい」で、／must not とは／意味が／ちがいます。|have to는 must와 거의 같은 뜻입니다. don't have to는 「~하지 않아도 된다」로 must not과 뜻이 다릅니다.|have to和must意思幾乎相同。don't have to是「不必～」，和must not意思不同。
inf.noun|to不定詞（名詞的用法）|to부정사 (명사적 용법)|不定詞（名詞用法）|I want to go|to＋動詞の元の形で／「〜すること」。／want to 〜／like to 〜 の形で／よく使います。|to+동사원형으로 「~하는 것」. want to ~, like to ~ 형태로 자주 씁니다.|to＋原形動詞表示「做～這件事」，常用want to～、like to～。
inf.adv|to不定詞（副詞的用法）|to부정사 (부사적 용법)|不定詞（副詞用法）|I went to the park to play|「〜するために」と／目的を／表します。／動作の後ろに／to＋動詞を／続けます。|「~하기 위해」라는 목적을 나타냅니다. 동작 뒤에 to+동사를 붙입니다.|表示「為了～」的目的，在動作後面接to＋動詞。
gerund|動名詞（〜すること）|동명사 (~하는 것)|動名詞（做～這件事）|I enjoy swimming|動詞ing で／「〜すること」。／enjoy・finish・stop の後ろは／動名詞を／使います。|동사ing로 「~하는 것」. enjoy·finish·stop 뒤에는 동명사를 씁니다.|動詞ing表示「做～這件事」。enjoy、finish、stop後面要用動名詞。
comp.er|比較級（-er than）|비교급 (-er than)|比較級（-er than）|Ken is taller than Rin|2つを／比べて／「〜より…だ」は／形容詞＋er＋than。|두 개를 비교해 「~보다 …하다」는 형용사+er+than입니다.|比較兩者「比～更…」用形容詞＋er＋than。
comp.est|最上級（the -est）|최상급 (the -est)|最上級（the -est）|the tallest in the class|3つ以上で／「いちばん〜」は／the＋形容詞＋est。／範囲は／in や of で／表します。|셋 이상에서 「가장 ~」는 the+형용사+est입니다. 범위는 in이나 of로 나타냅니다.|三者以上「最～」用the＋形容詞＋est，範圍用in或of表示。
comp.more|more / most を使う比較|more / most 비교|用more / most的比較|more beautiful / the most popular|長い形容詞は／er・est の代わりに／more・most を／前に／置きます。|긴 형용사는 er·est 대신 more·most를 앞에 둡니다.|較長的形容詞不加er、est，而是在前面加more、most。
comp.as|as 〜 as（同じくらい）|as ~ as (~만큼)|as～as（一樣）|as tall as Ken|「〜と同じくらい…」は／as＋形容詞＋as。／not as 〜 as は／「〜ほど…ない」です。|「~만큼 …하다」는 as+형용사+as입니다. not as ~ as는 「~만큼 …하지 않다」입니다.|「和～一樣…」用as＋形容詞＋as。not as～as是「不如～」。
there|There is / There are|There is / There are|There is / There are|There is a cat on the bed|「〜がある・いる」は／There is（1つ）／There are（複数）で／表します。|「~이 있다」는 There is(하나) / There are(여럿)로 나타냅니다.|「有～」用There is（單數）／There are（複數）表示。
conj.when|接続詞 when|접속사 when|連接詞when|When I got home, ~|「〜するとき」は／when＋文。／文の前にも／後ろにも／置けます。|「~할 때」는 when+문장입니다. 문장 앞에도 뒤에도 둘 수 있습니다.|「當～的時候」用when＋句子，可放在句首或句尾。
conj.because|接続詞 because|접속사 because|連接詞because|I stayed home because it rained|理由を／表す／「〜なので」は／because＋文です。|이유를 나타내는 「~이니까」는 because+문장입니다.|表示理由「因為～」用because＋句子。
conj.if|接続詞 if|접속사 if|連接詞if|If it rains, I will stay home|「もし〜なら」は／if＋文。／未来のことでも／if の中は／現在形に／します。|「만약 ~라면」은 if+문장입니다. 미래의 일이라도 if 안은 현재형으로 씁니다.|「如果～」用if＋句子。即使是未來的事，if裡面也用現在式。
inf.adj|to不定詞（形容詞的用法）|to부정사 (형용사적 용법)|不定詞（形容詞用法）|something to drink|名詞の後ろに／to＋動詞を／置いて／「〜するための」「〜すべき」と／説明します。|명사 뒤에 to+동사를 두어 「~할」「~하기 위한」이라고 설명합니다.|在名詞後面加to＋動詞，說明「要～的」「用來～的」。
perfect.exp|現在完了（経験）|현재완료 (경험)|現在完成式（經驗）|I have visited Kyoto twice|「〜したことがある」は／have＋過去分詞。／ever・never・once・twice と／一緒に／よく使います。|「~한 적이 있다」는 have+과거분사입니다. ever·never·once·twice와 함께 자주 씁니다.|「曾經～」用have＋過去分詞，常和ever、never、once、twice一起使用。
perfect.done|現在完了（完了）|현재완료 (완료)|現在完成式（完成）|I have just finished|「もう〜した・ちょうど〜したところ」は／have＋過去分詞に／just・already・yet を／組み合わせます。|「이미 ~했다·막 ~했다」는 have+과거분사에 just·already·yet을 함께 씁니다.|「已經～・剛剛～」用have＋過去分詞搭配just、already、yet。
perfect.cont|現在完了（継続）|현재완료 (계속)|現在完成式（持續）|I have lived here for ten years|「ずっと〜している」は／have＋過去分詞。／for（期間）や／since（始まり）と／使います。|「계속 ~하고 있다」는 have+과거분사입니다. for(기간)나 since(시작)와 씁니다.|「一直～」用have＋過去分詞，搭配for（期間）或since（起點）。
perfect.neg|現在完了の否定・疑問|현재완료의 부정·의문|現在完成式的否定・疑問|I haven't finished yet / Have you ever ~?|否定は／have not＋過去分詞、／疑問は／Have を／先頭に／出します。／yet は／否定で／「まだ」です。|부정은 have not+과거분사, 의문은 Have를 앞으로 보냅니다. yet은 부정문에서 「아직」입니다.|否定用have not＋過去分詞，疑問把Have移到句首。yet在否定句中是「還沒」。
passive|受け身|수동태|被動語態|The castle was built in 1600|「〜される」は／be動詞＋過去分詞。／「だれに」は／by〜で／表します。|「~되다」는 be동사+과거분사입니다. 「누구에 의해」는 by ~로 나타냅니다.|「被～」用be動詞＋過去分詞，「被誰」用by～表示。
rel.who|関係代名詞 who|관계대명사 who|關係代名詞who|a friend who lives in Paris|人を／後ろから／説明するときは／who＋動詞を／続けます。|사람을 뒤에서 설명할 때는 who+동사를 이어 씁니다.|從後面說明人的時候，接who＋動詞。
rel.which|関係代名詞 which|관계대명사 which|關係代名詞which|the book which I bought|物や動物を／後ろから／説明するときは／which を／使います。|사물이나 동물을 뒤에서 설명할 때는 which를 씁니다.|從後面說明物品或動物時用which。
rel.that|関係代名詞 that|관계대명사 that|關係代名詞that|the movie that I saw|that は／人にも／物にも／使える／便利な／関係代名詞です。|that은 사람에게도 사물에도 쓸 수 있는 편리한 관계대명사입니다.|that是人和物都能用的方便關係代名詞。
participle|分詞（名詞を説明）|분사 (명사 수식)|分詞（修飾名詞）|the boy playing soccer / a broken window|「〜している」は／動詞ing、／「〜された」は／過去分詞で、／名詞を／説明します。|「~하고 있는」은 동사ing, 「~된」은 과거분사로 명사를 설명합니다.|「正在～的」用動詞ing，「被～的」用過去分詞來修飾名詞。
indirect|間接疑問文|간접의문문|間接疑問句|I know where he lives|文の中に／疑問文を／入れるときは／疑問詞＋主語＋動詞の／ふつうの語順に／します。|문장 안에 의문문을 넣을 때는 의문사+주어+동사의 평서문 어순으로 합니다.|在句子中放入疑問句時，用疑問詞＋主詞＋動詞的直述句語序。
inf.how|how to 〜（〜のしかた）|how to ~ (~하는 방법)|how to～（～的方法）|I know how to cook|「〜のしかた」は／how to＋動詞。／what to・where to も／同じ形です。|「~하는 방법」은 how to+동사입니다. what to·where to도 같은 형태입니다.|「～的方法」用how to＋動詞，what to、where to也是同樣的形式。
inf.it|It is 〜 to …|It is ~ to …|It is～to…|It is fun to learn English|「…することは〜だ」は／It を／仮の主語に／して、／本当の主語を／to 以下に／置きます。|「…하는 것은 ~이다」는 It을 가주어로 하고 진짜 주어를 to 이하에 둡니다.|「做…是～的」以It當形式主詞，真正的主詞放在to後面。
svoc|SVOC（AをBにする）|SVOC (A를 B로 만들다)|SVOC（使A成為B）|The news made us happy|make・call・keep は／「目的語＋説明の語」を／続けて、／「AをBにする」と／表せます。|make·call·keep 뒤에 「목적어+보어」를 이어 「A를 B로 만들다」를 나타냅니다.|make、call、keep後面接「受詞＋補語」，表示「使A成為B」。
svoo|SVOO（AにBをあげる）|SVOO (A에게 B를 주다)|SVOO（給A某物B）|She gave me a present|give・show・tell などは／「人＋物」の／順で／目的語を／2つ／とれます。|give·show·tell 등은 「사람+물건」 순으로 목적어 두 개를 가질 수 있습니다.|give、show、tell等可以按「人＋物」的順序接兩個受詞。
svc|SVC（〜に見える・聞こえる）|SVC (~처럼 보이다·들리다)|SVC（看起來・聽起來）|You look tired / That sounds great|look・sound・smell・feel の／後ろには／形容詞を／置いて、／様子を／表します。|look·sound·smell·feel 뒤에는 형용사를 두어 모습을 나타냅니다.|look、sound、smell、feel後面接形容詞，表示樣子。
causative|使役（make / let / have）|사역 (make / let / have)|使役（make / let / have）|My mom made me clean my room|「人に〜させる」は／make・let・have＋人＋動詞の元の形。／to は／つけません。|「사람에게 ~시키다」는 make·let·have+사람+동사원형입니다. to는 붙이지 않습니다.|「讓人～」用make、let、have＋人＋原形動詞，不加to。
perception|知覚動詞|지각동사|感官動詞|I saw him cross the road / I heard her singing|see・hear・feel＋人＋動詞（ing）で／「人が〜する（している）のを／見る・聞く」。|see·hear·feel+사람+동사(ing)로 「사람이 ~하는(하고 있는) 것을 보다·듣다」.|see、hear、feel＋人＋動詞（ing）表示「看到・聽到某人在做～」。
want.o.to|want＋人＋to 〜|want+사람+to ~|want＋人＋to～|I want you to come|「人に〜してほしい」は／want＋人＋to＋動詞です。|「사람이 ~해 주길 바라다」는 want+사람+to+동사입니다.|「希望某人～」用want＋人＋to＋動詞。
ask.o.to|ask＋人＋to 〜|ask+사람+to ~|ask＋人＋to～|She asked me to help|「人に〜するよう／頼む」は／ask＋人＋to＋動詞です。|「사람에게 ~해 달라고 부탁하다」는 ask+사람+to+동사입니다.|「請某人～」用ask＋人＋to＋動詞。
tell.o.to|tell＋人＋to 〜|tell+사람+to ~|tell＋人＋to～|The teacher told us to be quiet|「人に〜するよう／言う」は／tell＋人＋to＋動詞。／say は／この形では／使えません。|「사람에게 ~하라고 말하다」는 tell+사람+to+동사입니다. say는 이 형태로 쓸 수 없습니다.|「叫某人～」用tell＋人＋to＋動詞，say不能用這個句型。
past.perf|過去完了|과거완료|過去完成式|The train had left when I arrived|過去の／ある時点より／さらに前の／ことは／had＋過去分詞で／表します。|과거의 어느 시점보다 더 이전의 일은 had+과거분사로 나타냅니다.|比過去某時間點更早的事用had＋過去分詞表示。
past.prog|過去進行形|과거진행형|過去進行式|I was taking a shower|「（その時）〜していた」は／was・were＋動詞ing です。|「(그때) ~하고 있었다」는 was·were+동사ing입니다.|「（那時）正在～」用was、were＋動詞ing。
future.prog|未来進行形|미래진행형|未來進行式|I will be flying at this time tomorrow|「（その時）〜しているだろう」は／will be＋動詞ing です。|「(그때) ~하고 있을 것이다」는 will be+동사ing입니다.|「（那時）將會正在～」用will be＋動詞ing。
modal.perf|助動詞＋have＋過去分詞|조동사+have+과거분사|助動詞＋have＋過去分詞|He must have lost his way / I should have left|過去への／推量や／後悔を／表します。／must have は／「〜したにちがいない」、／should have は／「〜すべきだった」。|과거에 대한 추측이나 후회를 나타냅니다. must have는 「~했음에 틀림없다」, should have는 「~했어야 했다」.|表示對過去的推測或後悔。must have是「一定是～了」，should have是「早該～」。
subj.past|仮定法過去|가정법 과거|假設語氣過去式|If I were a bird, I could fly|今の事実と／ちがうことは／過去形で／表します。／If＋過去形, would・could＋動詞。／be動詞は／were が／基本です。|현재 사실과 다른 일은 과거형으로 나타냅니다. If+과거형, would·could+동사. be동사는 were가 기본입니다.|與現在事實相反的事用過去式表示。If＋過去式，would、could＋動詞，be動詞基本用were。
subj.pp|仮定法過去完了|가정법 과거완료|假設語氣過去完成式|If I had known, I would have helped|過去の事実と／ちがうことは／If＋had＋過去分詞, would have＋過去分詞で／表します。|과거 사실과 다른 일은 If+had+과거분사, would have+과거분사로 나타냅니다.|與過去事實相反的事用If＋had＋過去分詞，would have＋過去分詞表示。
wish|I wish 〜（〜ならいいのに）|I wish ~ (~라면 좋을 텐데)|I wish～（要是～就好了）|I wish I could fly|かなわない／願いは／I wish＋過去形。／過去への／後悔は／I wish＋had＋過去分詞です。|이루어지지 않는 소원은 I wish+과거형. 과거에 대한 후회는 I wish+had+과거분사입니다.|無法實現的願望用I wish＋過去式，對過去的後悔用I wish＋had＋過去分詞。
as.if|as if（まるで〜のように）|as if (마치 ~처럼)|as if（好像～）|He talks as if he knew everything|「まるで〜のように」は／as if＋過去形（仮定法）で／表します。|「마치 ~처럼」은 as if+과거형(가정법)으로 나타냅니다.|「好像～一樣」用as if＋過去式（假設語氣）表示。
without|without（〜がなければ）|without (~이 없다면)|without（如果沒有～）|Without your help, I would have failed|without＋名詞で／「〜がなければ（なかったら）」と／仮定を／表せます。|without+명사로 「~이 없다면(없었다면)」이라는 가정을 나타냅니다.|without＋名詞可以表示「如果沒有～」的假設。
rel.what|関係代名詞 what|관계대명사 what|關係代名詞what|What you said is true|what は／「〜すること・〜するもの」の／意味で、／先行詞を／ふくんでいます。|what은 「~하는 것」이라는 뜻으로, 선행사를 포함하고 있습니다.|what表示「～的事物」，本身已包含先行詞。
rel.where|関係副詞 where|관계부사 where|關係副詞where|the town where I was born|場所を／後ろから／説明するときは／where＋文を／続けます。|장소를 뒤에서 설명할 때는 where+문장을 이어 씁니다.|從後面說明地點時接where＋句子。
rel.when|関係副詞 when|관계부사 when|關係副詞when|the day when we met|時を／後ろから／説明するときは／when＋文を／続けます。|때를 뒤에서 설명할 때는 when+문장을 이어 씁니다.|從後面說明時間時接when＋句子。
rel.whose|関係代名詞 whose|관계대명사 whose|關係代名詞whose|a friend whose father is a pilot|「その人の〜が」と／持ち主を／表すときは／whose＋名詞を／使います。|「그 사람의 ~가」라고 소유를 나타낼 때는 whose+명사를 씁니다.|表示「那個人的～」的所有關係時用whose＋名詞。
rel.nonres|関係代名詞（コンマつき）|관계대명사 (콤마 용법)|關係代名詞（非限定用法）|My brother, who lives in Tokyo, is a doctor|コンマの後ろの／who・which は／「ちなみに〜」と／情報を／付け足します。／that は／使えません。|콤마 뒤의 who·which는 「참고로 ~」라고 정보를 덧붙입니다. that은 쓸 수 없습니다.|逗號後面的who、which用來補充資訊，不能用that。
participle.const|分詞構文|분사구문|分詞構句|Listening to music, she did her homework|接続詞と／主語を／省いて、／動詞ing（受け身なら／過去分詞）で／「〜しながら・〜なので」を／表します。|접속사와 주어를 생략하고 동사ing(수동이면 과거분사)로 「~하면서·~해서」를 나타냅니다.|省略連接詞和主詞，用動詞ing（被動用過去分詞）表示「一邊～・因為～」。
with.oc|with＋名詞＋分詞|with+명사+분사|with＋名詞＋分詞|with his eyes closed|「〜を…したまま」は／with＋名詞＋分詞で／表します。|「~를 …한 채로」는 with+명사+분사로 나타냅니다.|「讓～保持…的狀態」用with＋名詞＋分詞表示。
if.only|If only 〜!（〜でさえあれば）|If only ~! (~이기만 하면!)|If only～!（要是～就好了）|If only I had studied more!|I wish より／強い気持ちの／「〜でさえあればなあ！」です。|I wish보다 강한 마음의 「~이기만 하면!」입니다.|比I wish語氣更強的「要是～就好了！」。
cleft|強調構文 It is 〜 that|강조구문 It is ~ that|強調句It is～that|It was Ken that broke the window|強調したい／語を／It is と／that の／間に／はさみます。|강조하고 싶은 말을 It is와 that 사이에 넣습니다.|把要強調的詞放在It is和that之間。
inversion|倒置|도치|倒裝|Never have I seen such a view|Never・Little・Rarely を／文の先頭に／出すと、／後ろは／疑問文の／語順に／なります。|Never·Little·Rarely를 문장 앞에 두면 뒤는 의문문 어순이 됩니다.|把Never、Little、Rarely放在句首時，後面變成疑問句語序。
emphasis.do|do による強調|do에 의한 강조|用do強調|I do believe you|動詞の前に／do・does・did を／置くと／「本当に〜する」と／強調できます。|동사 앞에 do·does·did를 두면 「정말로 ~하다」라고 강조할 수 있습니다.|在動詞前加do、does、did可以強調「真的～」。
not.only|not only A but also B|not only A but also B|not only A but also B|He is not only kind but also smart|「AだけでなくBも」は／not only A but also B。／文の先頭に／置くと／倒置に／なります。|「A뿐만 아니라 B도」는 not only A but also B입니다. 문장 앞에 두면 도치가 됩니다.|「不只A，B也～」用not only A but also B，放在句首時要倒裝。
logic.however|However（しかし）|However (하지만)|However（然而）|It was raining. However, we went out.|However は／文と文を／つなぐ／「しかし」。／後ろに／コンマを／置きます。|However는 문장과 문장을 잇는 「하지만」입니다. 뒤에 콤마를 둡니다.|However是連接兩個句子的「然而」，後面加逗號。
logic.therefore|Therefore（だから）|Therefore (그러므로)|Therefore（因此）|He studied hard. Therefore, he passed.|Therefore は／「それゆえ・だから」と／結論を／みちびきます。|Therefore는 「그러므로」라고 결론을 이끕니다.|Therefore表示「因此」，引出結論。
logic.although|Although（〜だけれども）|Although (~이지만)|Although（雖然）|Although she was tired, she kept running|Although＋文で／「〜だけれども」。／but と／ちがい、／文の前に／置けます。|Although+문장으로 「~이지만」. but과 달리 문장 앞에 둘 수 있습니다.|Although＋句子表示「雖然～」，和but不同，可以放在句首。
logic.unless|Unless（〜しない限り）|Unless (~하지 않으면)|Unless（除非）|You will be late unless you hurry|unless は／「〜しない限り・〜しなければ」。／if not と／ほぼ同じです。|unless는 「~하지 않으면」. if not과 거의 같습니다.|unless表示「除非～・如果不～」，和if not差不多。
logic.whereas|Whereas（一方で）|Whereas (반면에)|Whereas（然而・反之）|He is tall, whereas I am short|2つの／ことを／対比して／「〜だが、一方で…」と／言うときに／使います。|두 가지를 대비해 「~이지만 반면에 …」라고 말할 때 씁니다.|對比兩件事「～，而…」時使用。
logic.so.that|so that（〜するように）|so that (~하도록)|so that（以便）|Speak loudly so that everyone can hear|so that＋主語＋can で／「〜できるように」と／目的を／表します。|so that+주어+can으로 「~할 수 있도록」이라는 목적을 나타냅니다.|so that＋主詞＋can表示「以便能～」的目的。
logic.in.case|in case（〜するといけないから）|in case (~할 경우에 대비해)|in case（以防）|Take an umbrella in case it rains|「〜の場合に／そなえて」は／in case＋文です。|「~할 경우에 대비해」는 in case+문장입니다.|「以防～」用in case＋句子。
nominal.whether|whether（〜かどうか）|whether (~인지 아닌지)|whether（是否）|I don't know whether he will come|「〜かどうか」は／whether＋文。／文の主語にも／なれます。|「~인지 아닌지」는 whether+문장입니다. 문장의 주어도 될 수 있습니다.|「是否～」用whether＋句子，也可以當主詞。
nominal.the.fact|the fact that 〜|the fact that ~|the fact that～|the fact that he is honest|「〜という事実」は／the fact that＋文で、／内容を／説明します。|「~라는 사실」은 the fact that+문장으로 내용을 설명합니다.|「～這個事實」用the fact that＋句子說明內容。
comparison.the|the 比較級, the 比較級|the 비교급, the 비교급|the比較級, the比較級|The more you practice, the better you become|「〜すればするほど…」は／the＋比較級を／2回／使います。|「~하면 할수록 …」는 the+비교급을 두 번 씁니다.|「越～就越…」用兩次the＋比較級。
no.sooner|No sooner 〜 than …|No sooner ~ than …|No sooner～than…|No sooner had I got home than it rained|「〜するとすぐに…」は／No sooner＋had＋主語＋過去分詞＋than＋過去形。|「~하자마자 …」는 No sooner+had+주어+과거분사+than+과거형입니다.|「一～就…」用No sooner＋had＋主詞＋過去分詞＋than＋過去式。
logic.as.long|as long as（〜する限り）|as long as (~하는 한)|as long as（只要）|You can stay as long as you are quiet|「〜しさえすれば・〜する限り」と／条件を／表します。|「~하기만 하면·~하는 한」이라는 조건을 나타냅니다.|表示「只要～」的條件。
logic.despite|despite / in spite of（〜にもかかわらず）|despite / in spite of (~에도 불구하고)|despite / in spite of（儘管）|Despite the rain, the game continued|後ろに／名詞や／動詞ing を／置いて／「〜にもかかわらず」。／文は／続けられません。|뒤에 명사나 동사ing를 두어 「~에도 불구하고」. 문장은 이어 쓸 수 없습니다.|後面接名詞或動詞ing表示「儘管～」，不能接句子。
emphasis.very|the very 〜（まさにその〜）|the very ~ (바로 그 ~)|the very～（正是那個～）|This is the very book I wanted|名詞の前の／very は／「まさにその」と／強調します。|명사 앞의 very는 「바로 그」라고 강조합니다.|名詞前面的very表示「正是那個」的強調。
"""
}
