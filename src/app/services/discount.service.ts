import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root'
})
export class DiscountService {
  private discountProductIds: Set<number> = new Set();
  private readonly STORAGE_KEY = 'discount_product_ids';

  constructor() {
    // Load from localStorage on init
    this.loadFromStorage();
  }

  // Load discount products from localStorage
  private loadFromStorage(): void {
    try {
      const stored = localStorage.getItem(this.STORAGE_KEY);
      if (stored) {
        const ids = JSON.parse(stored);
        this.discountProductIds = new Set(ids);
        console.log('🏷️ Discount products loaded from cache:', ids.length, 'products');
      }
    } catch (e) {
      console.error('❌ Error loading discount cache:', e);
    }
  }

  // Save discount products to localStorage
  private saveToStorage(): void {
    try {
      const ids = Array.from(this.discountProductIds);
      localStorage.setItem(this.STORAGE_KEY, JSON.stringify(ids));
    } catch (e) {
      console.error('❌ Error saving discount cache:', e);
    }
  }

  // Set which products are currently on discount (called by discounts page)
  setDiscountProducts(productIds: number[]): void {
    this.discountProductIds = new Set(productIds);
    this.saveToStorage();
    console.log('🏷️ Discount products updated:', productIds.length, 'products');
  }

  // Check if a product is on discount
  isProductOnDiscount(productId: number): boolean {
    return this.discountProductIds.has(productId);
  }

  // Get all discount product IDs
  getDiscountProductIds(): number[] {
    return Array.from(this.discountProductIds);
  }

  // Calculate display price (returns p_price if discounted, otherwise price)
  getDisplayPrice(product: any): number {
    if (this.isProductOnDiscount(product.id)) {
      return product.pPrice || product.price;
    }
    return product.price;
  }

  // Check if product has discount (pPrice < price AND is in discount list)
  hasDiscount(product: any): boolean {
    if (!this.isProductOnDiscount(product.id)) {
      return false;
    }
    return product.pPrice < product.price;
  }

  // Clear discount cache (optional - for logout or cache invalidation)
  clearCache(): void {
    this.discountProductIds.clear();
    localStorage.removeItem(this.STORAGE_KEY);
    console.log('🏷️ Discount cache cleared');
  }
}