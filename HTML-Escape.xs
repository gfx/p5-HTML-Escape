#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#define NEED_newSV_type
#include "ppport.h"


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

static bool
str_is_raw(pTHX_ pMY_CXT_ SV* const sv) {
    if(SvROK(sv) && SvOBJECT(SvRV(sv))) {
        return SvTYPE(SvRV(sv)) <= SVt_PVMG
            && SvSTASH(SvRV(sv)) == MY_CXT.raw_stash;
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

static void
html_concat_with_force_escape(pTHX_ SV* const dest, SV* const src) {
    STRLEN len;
    const char*       cur = SvPV_const(src, len);
    const char* const end = cur + len;

    (void)SvGROW(dest, SvCUR(dest) + len);
    if(!SvUTF8(dest) && SvUTF8(src)) {
        sv_utf8_upgrade(dest);
    }

    while(cur != end) {
        const char* parts;
        STRLEN      parts_len;

        switch(*cur) {
        case '<':
            parts     =        "&lt;";
            parts_len = sizeof("&lt;") - 1;
            break;
        case '>':
            parts     =        "&gt;";
            parts_len = sizeof("&gt;") - 1;
            break;
        case '&':
            parts     =        "&amp;";
            parts_len = sizeof("&amp;") - 1;
            break;
        case '"':
            parts     =        "&quot;";
            parts_len = sizeof("&quot;") - 1;
            break;
        case '\'':
            parts     =        "&apos;";
            parts_len = sizeof("&apos;") - 1;
            break;
        default:
            parts     = cur;
            parts_len = 1;
            len       = SvCUR(dest) + 2; /* parts_len + 1 */
            SvGROW(dest, len);
            *SvEND(dest) = *parts;
            SvCUR_set(dest, SvCUR(dest) + 1);
            goto loop_continue;
            break;
        }

        /* copy special characters */

        len = SvCUR(dest) + parts_len + 1;
        (void)SvGROW(dest, len);

        Copy(parts, SvEND(dest), parts_len, char);

        SvCUR_set(dest, SvCUR(dest) + parts_len);

        loop_continue:
        cur++;
    }
    *SvEND(dest) = '\0';
}

static SV*
html_escape(pTHX_ pMY_CXT_ SV* const str) {
    if(!SvOK(str) || STR_IS_RAW(str)) {
        return str;
    }
    else {
        SV* const dest = newSVpvs_flags("", SVs_TEMP);
        html_concat_with_force_escape(aTHX_ dest, str);
        return WRAP_RAW(dest);
    }
}

static void
html_concat(pTHX_ pMY_CXT_ SV* const lhs, SV* const rhs) {
    if(!STR_IS_RAW(lhs)) {
        SV* const raw = html_escape(aTHX_ aMY_CXT_ lhs);
        sv_setsv(lhs, raw);
    }

    {
        SV* const sv = GET_STR(lhs);

        if(STR_IS_RAW(rhs)) {
            sv_catsv(sv, GET_STR(rhs));
        }
        else {
            html_concat_with_force_escape(aTHX_ sv, rhs);
        }
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
html_escape_force(SV* sv)
CODE:
{
    dMY_CXT;
    SV* const dest = newSVpvs_flags("", SVs_TEMP);
    html_concat_with_force_escape(aTHX_ dest, UNMARK_RAW(sv));
    ST(0) = WRAP_RAW(dest);
    XSRETURN(1);
}

void
html_concat(SV* lhs, ...)
CODE:
{
    dMY_CXT;
    I32 i;
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
    SV* const result = newSVpvs_flags("", SVs_TEMP);
    if(items > 1) {
        I32 i;
        sv_grow(result, 64 * items);

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
new(SV* klass, SV* str)
CODE:
{
    dMY_CXT;
    if(sv_isobject(klass)) {
        croak("You cannot call %s->new() as an instance method", RAW_CLASS);
    }
    if(strNE(SvPV_nolen_const(klass), RAW_CLASS)) {
        croak("You cannot extend %s", RAW_CLASS);
    }
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
    lhs = raw_clone(aTHX_ aMY_CXT_ lhs);
    html_concat(aTHX_ aMY_CXT_ lhs, rhs);
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
        ST(0)         = lhs;
    }
    html_concat(aTHX_ aMY_CXT_ lhs, rhs);
    XSRETURN(1);
}
