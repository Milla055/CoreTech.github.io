import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterLink } from '@angular/router';
import { HeaderComponent } from "../header/header.component";
import { FooterComponent } from "../footer/footer.component";
import { ProductcardComponent } from "../productcard/productcard.component";
import { ProductService, Product } from '../services/product.service';
import { DiscountService } from '../services/discount.service';

@Component({
  selector: 'app-mainpage',
  standalone: true,
  imports: [CommonModule, HeaderComponent, FooterComponent, RouterLink, ProductcardComponent],
  templateUrl: './mainpage.component.html',
  styleUrl: './mainpage.component.css',
})
export class MainpageComponent implements OnInit {
  discountProducts: Product[] = [];
  top50Products: Product[] = [];
  loading: boolean = true;

  constructor(
    private productService: ProductService,
    private router: Router,
    private discountService: DiscountService
  ) {}

  ngOnInit(): void {
    this.loadDiscountProducts();
    this.loadTop50Products();
  }

  loadDiscountProducts(): void {
    this.productService.getAllProducts().subscribe({
      next: (products) => {
        // Same seeded random as discounts page - 3 day rotation
        const daysSinceEpoch = Math.floor(Date.now() / (1000 * 60 * 60 * 24));
        let seed = Math.floor(daysSinceEpoch / 3);

        const rng = () => {
          seed = (seed * 1664525 + 1013904223) & 0xffffffff;
          return (seed >>> 0) / 0xffffffff;
        };

        const shuffled = [...products];
        for (let i = shuffled.length - 1; i > 0; i--) {
          const j = Math.floor(rng() * (i + 1));
          [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
        }

        // Take first 4 products for display on mainpage
        this.discountProducts = shuffled.slice(0, 4);
        
        // DON'T register here - let discounts page do it!
        // The mainpage just SHOWS the same products but doesn't control discount logic
        
        this.loading = false;
      },
      error: (err) => {
        console.error('Error loading products:', err);
        this.loading = false;
      }
    });
  }

  loadTop50Products(): void {
    this.productService.getAllProducts().subscribe({
      next: (products) => {
        // DIFFERENT seed than discounts (+999 offset)
        const daysSinceEpoch = Math.floor(Date.now() / (1000 * 60 * 60 * 24));
        let seed = Math.floor(daysSinceEpoch / 3) + 999;

        const rng = () => {
          seed = (seed * 1664525 + 1013904223) & 0xffffffff;
          return (seed >>> 0) / 0xffffffff;
        };

        const shuffled = [...products];
        for (let i = shuffled.length - 1; i > 0; i--) {
          const j = Math.floor(rng() * (i + 1));
          [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
        }

        // Take first 4 products for mainpage Top50 section
        this.top50Products = shuffled.slice(0, 4);
      },
      error: (err) => {
        console.error('Error loading Top50 products:', err);
      }
    });
  }

  goToDiscounts(): void {
    this.router.navigate(['/discounts']);
  }

  goToTop50(): void {
    this.router.navigate(['/top50']);
  }
}