#define NEED_newSV_type
#include "perlxs.h"

#include "html_escape.h"

#define RAW_CLASS "HTML::Escape::RawString"

#define GET_STR(sv)    SvRV(sv)
#define STR_IS_RAW(sv) str_is_raw(aTHX_ aMY_CXT_ sv)
#define WRAP_RAW(sv)   wrap_raw(aTHX_ aMY_CXT_ sv)
#define UNMARK_RAW(sv) unmark_raw(aTHX_ aMY_CXT_ sv)

#define MY_CXT_KEY RAW_CLASS "::_guts" XS_VERSION
typedef struct {
    HV* raw_stash;
} my_cxt_t;
START_MY_CXT

static SV*
new_buffer(pTHX) {
    SV* const sv = newSV_type(SVt_PV);
    sv_grow(sv, 128);
    SvPOK_on(sv);
    return sv_2mortal(sv);
}

static bool
str_is_raw(pTHX_ pMY_CXT_ SV* const sv) {
    if(SvROK(sv)) {
        SV* const thing = SvRV(sv);
        return SvOBJECT(thing)
                && SvSTASH(thing) == MY_CXT.raw_stash
                && SvTYPE(thing) <= SVt_PVMG;
    }
    return FALSE;
}

static SV*
wrap_raw(pTHX_ pMY_CXT_ SV* const sv) {
    SV* const dest = newSV_type(SVt_PVMG);
    sv_setsv(dest, sv);
    return sv_2mortal(sv_bless(newRV_noinc(dest), MY_CXT.raw_stash));
}

static SV*
mark_raw(pTHX_ pMY_CXT_ SV* const str) {
    if(STR_IS_RAW(str)) {
        return str;
    }
    else {
        return WRAP_RAW(str);
    }
}

static SV*
unmark_raw(pTHX_ pMY_CXT_ SV* const str) {
    if(STR_IS_RAW(str)) {
        return GET_STR(str);
    }
    else {
        return str;
    }
}

/* does sv_catsv_nomg(dest, src), but significantly faster */
static void
my_sv_cat(pTHX_ SV* const dest, SV* const src) {
    if(!SvUTF8(dest) && SvUTF8(src)) {
        sv_utf8_upgrade(dest);
    }

    {
        STRLEN len;
        const char* const pv  = SvPV_const(src, len);
        STRLEN const dest_cur = SvCUR(dest);
        char* const d         = SvGROW(dest, dest_cur + len + 1 /* count '\0' */);

        Copy(pv, d + dest_cur, len + 1 /* copy '\0' */, char);
        SvCUR_set(dest, dest_cur + len);
    }
}


static void
html_concat_with_force_escape(pTHX_ SV* const dest, SV* const src) {
    STRLEN len;
    const char*       cur = SvPV_const(src, len);
    const char* const end = cur + len;
    STRLEN dest_cur       = SvCUR(dest);

    (void)SvGROW(dest, SvCUR(dest) + len);
    if(!SvUTF8(dest) && SvUTF8(src)) {
        sv_utf8_upgrade(dest);
    }

    while(cur != end) {
        /* preallocate the buffer for at least max parts_len + 1 */
        char* const d = SvGROW(dest, dest_cur + 8) + dest_cur;
        const entity_t* const e = char_trait[(U8)*cur];
        if(e) {
            Copy(e->entity, d, e->entity_len, char);
            dest_cur += e->entity_len;
        }
        else {
            *d = *cur;
            dest_cur++;
        }

        cur++;
    }
    SvCUR_set(dest, dest_cur);
    *SvEND(dest) = '\0';
}

static SV*
html_escape(pTHX_ pMY_CXT_ SV* const str) {
    if(!SvOK(str) || STR_IS_RAW(str)) {
        return str;
    }
    else {
        SV* const dest = new_buffer(aTHX);
        html_concat_with_force_escape(aTHX_ dest, str);
        return WRAP_RAW(dest);
    }
}

static void
html_concat(pTHX_ pMY_CXT_ SV* const lhs, SV* const rhs) {
    if(STR_IS_RAW(rhs)) {
        my_sv_cat(aTHX_ lhs, GET_STR(rhs));
    }
    else {
        html_concat_with_force_escape(aTHX_ lhs, rhs);
    }
}

static SV*
raw_clone(pTHX_ pMY_CXT_ SV* const sv) {
    return WRAP_RAW( UNMARK_RAW(sv) );
}

/* Because overloading stuff of old xsubpp didn't work,
   we need to copy them. */
XS(XS_HTML__Escape_fallback); /* prototype to pass -Wmissing-prototypes */
XS(XS_HTML__Escape_fallback)
{
   dXSARGS;
   PERL_UNUSED_VAR(cv);
   PERL_UNUSED_VAR(items);
   XSRETURN_EMPTY;
}

static void
my_cxt_init(pTHX_ pMY_CXT_ bool const cloning PERL_UNUSED_DECL) {
    MY_CXT.raw_stash = gv_stashpvs(RAW_CLASS, GV_ADDMULTI);
}


MODULE = HTML::Escape	PACKAGE = HTML::Escape

PROTOTYPES: DISABLE

BOOT:
{
    SV* code_ref;
    MY_CXT_INIT;
    my_cxt_init(aTHX_ aMY_CXT_ FALSE);

    newCONSTSUB(gv_stashpvs("HTML::Escape", GV_ADDMULTI),
        "RAW_STRING_CLASS", newSVpvs(RAW_CLASS));

    /* overload stuff */
    PL_amagic_generation++;
    sv_setsv(
        get_sv( RAW_CLASS "::()", TRUE ),
        &PL_sv_yes
    );
    (void)newXS( RAW_CLASS "::()",
        XS_HTML__Escape_fallback, file);

    /* *{'(""'} = \&as_string */
    code_ref = sv_2mortal(newRV_inc((SV*)get_cv( RAW_CLASS "::as_string", GV_ADD)));
    sv_setsv_mg(
        (SV*)gv_fetchpvs( RAW_CLASS "::(\"\"", GV_ADDMULTI, SVt_PVCV),
        code_ref);

    /* *{'(='} = \&clone */
    code_ref = sv_2mortal(newRV_inc((SV*)get_cv( RAW_CLASS "::clone", GV_ADD)));
    sv_setsv_mg(
        (SV*)gv_fetchpvs( RAW_CLASS "::(=", GV_ADDMULTI, SVt_PVCV),
        code_ref);

    /* *{'(.'} = \&clone_and_concat */
    code_ref = sv_2mortal(newRV_inc((SV*)get_cv( RAW_CLASS "::clone_and_concat", GV_ADD)));
    sv_setsv_mg(
        (SV*)gv_fetchpvs( RAW_CLASS "::(.", GV_ADDMULTI, SVt_PVCV),
        code_ref);

    /* *{'(.='} = \&concat */
    code_ref = sv_2mortal(newRV_inc((SV*)get_cv( RAW_CLASS "::concat", GV_ADD)));
    sv_setsv_mg(
        (SV*)gv_fetchpvs( RAW_CLASS "::(.=", GV_ADDMULTI, SVt_PVCV),
        code_ref);
}

#ifdef USE_ITHREADS

void
CLONE(...)
CODE:
{
    MY_CXT_CLONE;
    my_cxt_init(aTHX_ aMY_CXT_ TRUE);
    PERL_UNUSED_VAR(items);
}

#endif


void
mark_raw(SV* sv)
CODE:
{
    dMY_CXT;
    ST(0) = mark_raw(aTHX_ aMY_CXT_ sv);
    XSRETURN(1);
}

void
unmark_raw(SV* sv)
CODE:
{
    dMY_CXT;
    ST(0) = UNMARK_RAW(sv);
    XSRETURN(1);
}

void
html_escape(SV* sv)
CODE:
{
    dMY_CXT;
    ST(0) = html_escape(aTHX_ aMY_CXT_ sv);
    XSRETURN(1);
}

void
html_concat(SV* lhs, ...)
CODE:
{
    dMY_CXT;
    I32 i;
    if(STR_IS_RAW(lhs)) {
        lhs = GET_STR(lhs);
    }
    for(i = 1; i < items; i++) {
        html_concat(aTHX_ aMY_CXT_ lhs, ST(i));
    }
    XSRETURN(1);
}

void
html_join(SV* sep, ...)
CODE:
{
    dMY_CXT;
    SV* const result = new_buffer(aTHX);
    if(items > 1) {
        I32 i;
        html_concat(aTHX_ aMY_CXT_ result, ST(1));
        for(i = 2; i < items; i++) {
            html_concat(aTHX_ aMY_CXT_ result, sep);
            html_concat(aTHX_ aMY_CXT_ result, ST(i));
        }
    }
    ST(0) = WRAP_RAW(result);
    XSRETURN(1);
}

MODULE = HTML::Escape	PACKAGE = HTML::Escape::RawString

void
new(SV* klass, SV* str = &PL_sv_no)
CODE:
{
    dMY_CXT;
    if(sv_isobject(klass)) {
        croak("You cannot call %s->new() as an instance method", RAW_CLASS);
    }
    if(strNE(SvPV_nolen_const(klass), RAW_CLASS)) {
        croak("You cannot extend %s", RAW_CLASS);
    }
    SvGETMAGIC(str);
    ST(0) = raw_clone(aTHX_ aMY_CXT_ str);
    XSRETURN(1);
}


void
as_string(SV* sv, ...)
CODE:
{
    dMY_CXT;
    ST(0) = UNMARK_RAW(sv);
    XSRETURN(1);
}

void
clone(SV* proto, ...)
CODE:
{
    dMY_CXT;
    ST(0) = raw_clone(aTHX_ aMY_CXT_ proto);
    XSRETURN(1);
}

void
clone_and_concat(SV* lhs, SV* rhs, SV* reversed = &PL_sv_no)
CODE:
{
    /* infix:<.> */
    dMY_CXT;
    if(sv_true(reversed)) {
        SV* const tmp = lhs;
        lhs           = rhs;
        rhs           = tmp;

        lhs = html_escape(aTHX_ aMY_CXT_ lhs);
    }
    else {
        lhs = raw_clone(aTHX_ aMY_CXT_ lhs);
    }
    html_concat(aTHX_ aMY_CXT_ GET_STR(lhs), rhs);
    ST(0) = lhs;
    XSRETURN(1);
}

void
concat(SV* lhs, SV* rhs, SV* reversed = &PL_sv_no)
CODE:
{
    /* infix:<.=> */
    dMY_CXT;
    if(sv_true(reversed)) {
        SV* const tmp = lhs;
        lhs           = rhs;
        rhs           = tmp;

        if(!STR_IS_RAW(lhs)) {
            /* upgrade */
            SV* const sv = WRAP_RAW(lhs);
            sv_setsv(lhs, sv);
        }
    }
    else {
        if(!STR_IS_RAW(lhs)) {
            croak("Not a raw string");
        }
    }
    html_concat(aTHX_ aMY_CXT_ GET_STR(lhs), rhs);
    ST(0) = lhs;
    XSRETURN(1);
}
