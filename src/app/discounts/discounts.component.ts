import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HeaderComponent } from '../header/header.component';
import { FooterComponent } from '../footer/footer.component';
import { ProductcardComponent } from '../productcard/productcard.component';
import { ProductService, Product } from '../services/product.service';
import { DiscountService } from '../services/discount.service';

@Component({
  selector: 'app-discounts',
  standalone: true,
  imports: [CommonModule, HeaderComponent, FooterComponent, ProductcardComponent],
  templateUrl: './discounts.component.html',
  styleUrl: './discounts.component.css',
})
export class DiscountsComponent implements OnInit {
  discountProducts: Product[] = [];
  loading: boolean = true;

  constructor(
    private productService: ProductService,
    private discountService: DiscountService
  ) {}

  ngOnInit(): void {
    this.productService.getAllProducts().subscribe({
      next: (products) => {
        this.discountProducts = this.selectDiscountProducts(products);
        
        // Register these products as discounted
        const discountIds = this.discountProducts.map(p => p.id);
        this.discountService.setDiscountProducts(discountIds);
        
        this.loading = false;
      },
      error: (err) => {
        console.error('Error loading products:', err);
        this.loading = false;
      }
    });
  }

  // Seeded random - 3 naponként ugyanazok a termékek mindenkinél
  private selectDiscountProducts(products: Product[]): Product[] {
    if (products.length === 0) return [];

    // Seed = hányadik 3 napos periódusban vagyunk
    const daysSinceEpoch = Math.floor(Date.now() / (1000 * 60 * 60 * 24));
    let seed = Math.floor(daysSinceEpoch / 3);

    // LCG pseudo-random
    const rng = () => {
      seed = (seed * 1664525 + 1013904223) & 0xffffffff;
      return (seed >>> 0) / 0xffffffff;
    };

    // Shuffle
    const shuffled = [...products];
    for (let i = shuffled.length - 1; i > 0; i--) {
      const j = Math.floor(rng() * (i + 1));
      [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
    }

    // 30-40 termék
    const count = Math.min(30 + Math.floor(rng() * 11), shuffled.length);
    return shuffled.slice(0, count);
  }
}