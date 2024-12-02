use std::ffi::{CStr, CString};

/// Make a keyword suitable for comparing to other keywords
///
/// # Examples
/// ```
/// use std::ffi::{CStr, CString};
///
/// let original = CString::new("My title /").unwrap().into_raw();
/// let result = unsafe { lib_jobs::normalize_keyword(original) };
/// assert_eq!(unsafe { CStr::from_ptr(result) }.to_str().unwrap(), "My title ");
/// ```
///
/// # Safety
///
/// Since this function reads arbitrary memory from a C pointer,
/// there are some safety considerations described in
/// <https://doc.rust-lang.org/std/ffi/struct.CStr.html#method.from_ptr>
#[no_mangle]
pub unsafe extern "C" fn normalize_keyword(raw_string_ptr: *const i8) -> *const i8 {
    let original_string = unsafe { CStr::from_ptr(raw_string_ptr) }.to_str().unwrap_or("");
    CString::new(normalize_string(original_string))
        .expect("Could not create a CString, check for 0 byte errors")
        .into_raw()
}

fn normalize_string(original_string: &str) -> &str {
    original_string.strip_suffix(|last_character: char| last_character.is_ascii_punctuation()).unwrap_or(original_string)
}

#[cfg(test)]
mod tests {
    use std::ffi::{CStr, CString};
    #[test]
    fn normalize_keyword() {
        let original = CString::new("31 pages.").unwrap().into_raw();
        let result = unsafe { super::normalize_keyword(original) };
        assert_eq!(
            unsafe { CStr::from_ptr(result) }.to_str().unwrap(),
            "31 pages"
        );
    }
}
