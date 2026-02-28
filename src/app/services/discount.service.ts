import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root'
})
export class DiscountService {
  private discountProductIds: Set<number> = new Set();

  // Set which products are currently on discount (called by discounts page)
  setDiscountProducts(productIds: number[]): void {
    this.discountProductIds = new Set(productIds);
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
}