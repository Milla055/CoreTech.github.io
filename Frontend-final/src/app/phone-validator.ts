// Hungarian phone number validator
// Valid formats:
// +36 XX XXX XXXX
// +36 XX XXX-XXXX
// +36XXXXXXXXX
// 06 XX XXX XXXX
// 06XXXXXXXXX

export class PhoneValidator {
  
  // Validate phone number format
  static isValid(phone: string): boolean {
    if (!phone) return false;
    
    // Remove all spaces, dashes, parentheses
    const cleaned = phone.replace(/[\s\-\(\)]/g, '');
    
    // Check if starts with +36 or 06
    const startsWithPlus36 = /^\+36[0-9]{9}$/.test(cleaned);
    const startsWith06 = /^06[0-9]{9}$/.test(cleaned);
    
    return startsWithPlus36 || startsWith06;
  }
  
  // Format phone number to +36 XX XXX XXXX
  static format(phone: string): string {
    if (!phone) return '';
    
    // Remove all non-digits and +
    let cleaned = phone.replace(/[^\d+]/g, '');
    
    // Convert 06 to +36
    if (cleaned.startsWith('06')) {
      cleaned = '+36' + cleaned.substring(2);
    }
    
    // Add +36 if missing
    if (!cleaned.startsWith('+36')) {
      cleaned = '+36' + cleaned;
    }
    
    // Extract digits after +36
    const digits = cleaned.substring(3);
    
    // Format as +36 XX XXX XXXX
    if (digits.length >= 9) {
      return `+36 ${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5, 9)}`;
    }
    
    return cleaned;
  }
  
  // Get error message for invalid phone
  static getErrorMessage(phone: string): string {
    if (!phone) {
      return 'Telefonszám megadása kötelező!';
    }
    
    const cleaned = phone.replace(/[\s\-\(\)]/g, '');
    
    if (!cleaned.startsWith('+36') && !cleaned.startsWith('06')) {
      return 'A telefonszámnak +36-tal vagy 06-tal kell kezdődnie!';
    }
    
    const digits = cleaned.replace(/^\+36|^06/, '');
    
    if (digits.length < 9) {
      return 'A telefonszám túl rövid! (9 számjegy szükséges)';
    }
    
    if (digits.length > 9) {
      return 'A telefonszám túl hosszú! (9 számjegy szükséges)';
    }
    
    if (!/^[0-9]+$/.test(digits)) {
      return 'A telefonszám csak számokat tartalmazhat!';
    }
    
    return 'Érvénytelen telefonszám formátum!';
  }
  
  // Real-time format as user types
  static formatAsTyping(input: string): string {
    // If empty, return empty (don't force +36)
    if (!input || input.trim() === '') {
      return '';
    }
    
    // Remove all non-digits and +
    let cleaned = input.replace(/[^\d+]/g, '');
    
    // Convert 06 to +36 (only if user typed 06, not just 0)
    if (cleaned.startsWith('06')) {
      cleaned = '+36' + cleaned.substring(2);
    }
    
    // If starts with + but not +36, keep as is (user typing +36)
    if (cleaned.startsWith('+') && !cleaned.startsWith('+36')) {
      return cleaned; // Let user finish typing +36
    }
    
    // If starts with single 0 (but not 06), keep as is - user might type 06
    if (cleaned === '0') {
      return cleaned;
    }
    
    // If starts with digits (but not 0 or 06), assume +36
    if (/^[1-9]/.test(cleaned)) {
      cleaned = '+36' + cleaned;
    }
    
    // If just '+' or doesn't start with +36, return as-is
    if (cleaned === '+' || !cleaned.startsWith('+36')) {
      return cleaned;
    }
    
    // Extract digits after +36
    const digits = cleaned.substring(3);
    
    // Build formatted string progressively
    let formatted = '+36';
    
    if (digits.length > 0) {
      formatted += ' ' + digits.substring(0, 2);
    }
    if (digits.length > 2) {
      formatted += ' ' + digits.substring(2, 5);
    }
    if (digits.length > 5) {
      formatted += ' ' + digits.substring(5, 9);
    }
    
    return formatted;
  }
}