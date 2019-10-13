unit sslang.zend_types;

interface

type

  TUnsignedShort = Word;
  TUnsignedInt = Cardinal;
  TUnsignedChar = Byte;
  TUInt32_t = TUnsignedInt;
  TUInt16_t = TUnsignedShort;
  TZendUChar = TUnsignedChar;
  TZendULong = TUInt32_t;
  TSize_t = TUnsignedInt;
  TInt32_t = Integer;
  TZendLong = TInt32_t;
  TZendBool = TUnsignedChar;
  PUnsignedChar = ^TUnsignedChar;
  PPUnsignedChar = ^PUnsignedChar;
  PSize_t = ^TSize_t;
  TZendAstKind = TUInt16_t;
  TZendAstAttr = TUInt16_t;
  PUInt32_t = ^TUInt32_t;
  TUInt = TUnsignedInt;
  ts_rsrc_id = integer;
  THREAD_T = DWORD;

  TZendValue = record
    case Integer of
       1: (lval: TZendLong);
       2: (dval: Double);
       3: (counted: PZendRefCounted);
       4: (str: PZendString);
       5: (arr: PZendArray);
       6: (obj: PZendObject);
       7: (res: PZendResource);
       8: (ref: PZendReference);
       9: (ast: PZendAstRef);
      10: (zv: Pzval);
      11: (ptr: Pointer);
      12: (ce: PZendClassEntry);
      13: (func: PZendFunction);
      14: (ww: record
            w1: TUInt32_t;
            w2: TUInt32_t;
          end);
  end;

  TZendValue = _zend_value;
  PZendValue = ^TZendValue;


  _zval_struct = record
    value: TZendValue;
    u1: record
      case Integer of
      1: (v: record
            type_: TZendUChar;
            type_flags: TZendUChar;
            const_flags: TZendUChar;
            reserved: TZendUChar;
          end);
      2: (type_info: TUInt32_t);
    end;
    u2: record
      case Integer of
        1: (var_flags: TUInt32_t);
        2: (next: TUInt32_t);
        3: (cache_slot: TUInt32_t);
        4: (lineno: TUInt32_t);
        5: (num_args: TUInt32_t);
        6: (fe_pos: TUInt32_t);
        7: (fe_iter_idx: TUInt32_t);
    end;
  end;

  Tzval = _zval_struct;

  _zend_reference = record
    gc: TZendRefCounted_h;
    val: Tzval;
  end;


implementation

end.
