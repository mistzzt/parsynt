function DfLength(s: seq<int>): int
{if s == [] then 0 else DfLength(s[..|s|-1]) + 1}

function Seen1(a : seq<bool>): bool
{
  if a == [] then false else (Seen1(a[..|a|-1]) || a[|a|-1])
}

function Res(a : seq<bool>): bool
{
  if a == [] then
    true
    else
    (((! a[|a|-1]) && Seen1(a[..|a|-1])) || Res(a[..|a|-1]))
}

function Seen1Join(leftSeen1 : bool, rightSeen1 : bool): bool
{
  (rightSeen1 || (leftSeen1 || false))
}

function ResJoin(leftRes : bool, leftSeen1 : bool, rightRes : bool, rightSeen1 : bool): bool
{
  (((rightSeen1 || rightRes) && (rightSeen1 || rightRes)) || (rightSeen1 || rightRes))
}


lemma BaseCaseSeen1(a : seq<bool>)
  ensures Seen1(a) == Seen1Join(Seen1(a), Seen1([]))
  {}

lemma HomSeen1(a : seq<bool>, R_a : seq<bool>)
  ensures Seen1(a + R_a) == Seen1Join(Seen1(a), Seen1(R_a))
  {
    if R_a == [] 
    {
    assert(a + [] == a);
    BaseCaseSeen1(a);
    
     } else {
    calc{
    Seen1(a + R_a);
    =={ assert(a + R_a[..|R_a|-1]) + [R_a[|R_a|-1]] == a + R_a; }
    Seen1Join(Seen1(a), Seen1(R_a));
    } // End calc.
  } // End else.
} // End lemma.

lemma BaseCaseRes(a : seq<bool>)
  ensures Res(a) == ResJoin(Res(a), Seen1(a), Res([]), Seen1([]))
  {}

lemma HomRes(a : seq<bool>, R_a : seq<bool>)
  ensures Res(a + R_a) == ResJoin(Res(a), Seen1(a), Res(R_a), Seen1(R_a))
  {
    if R_a == [] 
    {
    assert(a + [] == a);
    BaseCaseRes(a);
    
     } else {
    calc{
    Res(a + R_a);
    =={
      HomSeen1(a, R_a[..|R_a| - 1]);
      assert(a + R_a[..|R_a|-1]) + [R_a[|R_a|-1]] == a + R_a;
      }
    ResJoin(Res(a), Seen1(a), Res(R_a), Seen1(R_a));
    } // End calc.
  } // End else.
} // End lemma.
