import { clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

/**
 * Combines multiple class names and merges Tailwind CSS classes
 * @param {...string} inputs - Class names to combine
 * @returns {string} - Merged class names
 */
export function cn(...inputs) {
  return twMerge(clsx(inputs));
}

/**
 * Formats a date string to a human-readable format
 * @param {string} dateString - Date string to format
 * @param {Object} options - Formatting options
 * @returns {string} - Formatted date string
 */
export function formatDate(dateString, options = {}) {
  if (!dateString) return '';
  
  const defaultOptions = {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  };
  
  const mergedOptions = { ...defaultOptions, ...options };
  
  try {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', mergedOptions);
  } catch (error) {
    console.error('Error formatting date:', error);
    return dateString;
  }
}

/**
 * Formats a date range to a human-readable format
 * @param {string} startDate - Start date string
 * @param {string} endDate - End date string
 * @param {boolean} isCurrent - Whether the range is current
 * @param {Object} options - Formatting options
 * @returns {string} - Formatted date range
 */
export function formatDateRange(startDate, endDate, isCurrent = false, options = {}) {
  const start = formatDate(startDate, options);
  const end = isCurrent ? 'Present' : formatDate(endDate, options);
  
  return `${start} - ${end}`;
}

/**
 * Truncates a string to a specified length
 * @param {string} str - String to truncate
 * @param {number} length - Maximum length
 * @returns {string} - Truncated string
 */
export function truncate(str, length = 50) {
  if (!str) return '';
  if (str.length <= length) return str;
  
  return `${str.substring(0, length)}...`;
}

/**
 * Formats a file size to a human-readable format
 * @param {number} bytes - File size in bytes
 * @param {number} decimals - Number of decimal places
 * @returns {string} - Formatted file size
 */
export function formatFileSize(bytes, decimals = 2) {
  if (bytes === 0) return '0 Bytes';
  
  const k = 1024;
  const dm = decimals < 0 ? 0 : decimals;
  const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
  
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  
  return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
}

/**
 * Generates a unique ID
 * @param {string} prefix - Prefix for the ID
 * @returns {string} - Unique ID
 */
export function generateId(prefix = 'id') {
  return `${prefix}-${Math.random().toString(36).substring(2, 9)}`;
}

/**
 * Debounces a function
 * @param {Function} func - Function to debounce
 * @param {number} wait - Wait time in milliseconds
 * @returns {Function} - Debounced function
 */
export function debounce(func, wait = 300) {
  let timeout;
  
  return function executedFunction(...args) {
    const later = () => {
      clearTimeout(timeout);
      func(...args);
    };
    
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
  };
}

/**
 * Validates an email address
 * @param {string} email - Email address to validate
 * @returns {boolean} - Whether the email is valid
 */
export function isValidEmail(email) {
  const re = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
  return re.test(String(email).toLowerCase());
}

/**
 * Validates a phone number
 * @param {string} phone - Phone number to validate
 * @returns {boolean} - Whether the phone number is valid
 */
export function isValidPhone(phone) {
  const re = /^\+?[1-9]\d{1,14}$/;
  return re.test(String(phone).replace(/\D/g, ''));
}

/**
 * Formats a phone number
 * @param {string} phone - Phone number to format
 * @returns {string} - Formatted phone number
 */
export function formatPhone(phone) {
  if (!phone) return '';
  
  const cleaned = String(phone).replace(/\D/g, '');
  
  if (cleaned.length === 10) {
    return `(${cleaned.substring(0, 3)}) ${cleaned.substring(3, 6)}-${cleaned.substring(6, 10)}`;
  }
  
  return phone;
}

/**
 * Adds animation classes for page transitions
 * @param {string} direction - Direction of the transition ('in' or 'out')
 * @returns {string} - Animation classes
 */
export function pageTransition(direction = 'in') {
  if (direction === 'in') {
    return 'animate-in fade-in slide-in-from-right-4 duration-300';
  }
  
  return 'animate-out fade-out slide-out-to-left-4 duration-300';
}