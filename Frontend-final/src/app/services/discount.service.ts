import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { map, tap, catchError } from 'rxjs/operators';
import { Product } from './product.service';

@Injectable({
  providedIn: 'root'
})
export class DiscountService {
  private discountProductIds: Set<number> = new Set();
  private readonly STORAGE_KEY = 'discount_product_ids';
  private apiUrl = 'http://127.0.0.1:8080/coreTech3-1.0-SNAPSHOT/webresources/products';

  // Pre-built PC ID-k - ezeket kiszűrjük
  private readonly PREBUILT_PC_IDS = Array.from({ length: 25 }, (_, i) => 250 + i); // 250-274

  constructor(private http: HttpClient) {
    // Load from localStorage on init
    this.loadFromStorage();
  }

  private getHeaders() {
    return {
      headers: new HttpHeaders({
        'Content-Type': 'application/json'
      })
    };
  }

  // Seeded random number generator - 3 napos rotáció
  private createSeededRng(): () => number {
    const daysSinceEpoch = Math.floor(Date.now() / (1000 * 60 * 60 * 24));
    let seed = Math.floor(daysSinceEpoch / 3); // 3 naponta változik

    return () => {
      seed = (seed * 1664525 + 1013904223) & 0xffffffff;
      return (seed >>> 0) / 0xffffffff;
    };
  }

  // Select discount products with seeded randomization
  private selectDiscountProducts(products: Product[]): Product[] {
    if (products.length === 0) return [];

    const rng = this.createSeededRng();

    // Shuffle with seeded random
    const shuffled = [...products];
    for (let i = shuffled.length - 1; i > 0; i--) {
      const j = Math.floor(rng() * (i + 1));
      [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
    }

    // Select 30-40 products
    const count = Math.min(30 + Math.floor(rng() * 11), shuffled.length);
    return shuffled.slice(0, count);
  }

  // Get discounted products from backend
  getDiscountedProducts(): Observable<Product[]> {
    return this.http.get<any>(this.apiUrl, this.getHeaders()).pipe(
      map(response => {
        if (response.status === 'Success' && response.products) {
          // Map products and filter out pre-built PCs
          const allProducts = response.products
            .filter((p: any) => !this.PREBUILT_PC_IDS.includes(p.id))
            .map((p: any) => this.mapProduct(p));
          
          // Select discount products with seeded random
          const discountProducts = this.selectDiscountProducts(allProducts);
          
          // Update cache
          const discountIds = discountProducts.map((p: Product) => p.id);
          this.setDiscountProducts(discountIds);
          
          return discountProducts;
        }
        return [];
      }),
      catchError(err => {
        console.error('Error loading discounted products:', err);
        return of([]);
      })
    );
  }

  // Map backend product to Product interface
  private mapProduct(p: any): Product {
    return {
      id: p.id,
      name: p.name,
      description: p.description,
      properties: p.properties,
      price: p.price,
      pPrice: p.p_price || p.pPrice || p.price,
      stock: p.stock,
      imageUrl: p.image_url || '',
      categoryId: { id: p.category_id, name: p.category_name || '' },
      brandId: { id: p.brand_id, name: p.brand_name || '' },
      createdAt: p.created_at
    };
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

  // Calculate display price (returns p_price if on discount, otherwise price)
  getDisplayPrice(product: any): number {
    if (this.isProductOnDiscount(product.id)) {
      return product.pPrice || product.price;
    }
    return product.price;
  }

  // Check if product has discount (is in discount list AND pPrice < price)
  hasDiscount(product: any): boolean {
    if (!this.isProductOnDiscount(product.id)) {
      return false;
    }
    return product.pPrice && product.pPrice < product.price;
  }

  // Clear discount cache (optional - for logout or cache invalidation)
  clearCache(): void {
    this.discountProductIds.clear();
    localStorage.removeItem(this.STORAGE_KEY);
    console.log('🏷️ Discount cache cleared');
  }
}