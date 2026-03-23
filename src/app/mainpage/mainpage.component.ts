import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterLink } from '@angular/router';
import { HeaderComponent } from "../header/header.component";
import { FooterComponent } from "../footer/footer.component";
import { ProductcardComponent } from "../productcard/productcard.component";
import { ProductService, Product } from '../services/product.service';
import { DiscountService } from '../services/discount.service';
import { NewsletterComponent } from "../newsletter/newsletter.component";

@Component({
  selector: 'app-mainpage',
  standalone: true,
  imports: [CommonModule, HeaderComponent, FooterComponent, RouterLink, ProductcardComponent, NewsletterComponent],
  templateUrl: './mainpage.component.html',
  styleUrls: ['./mainpage.component.css']
})
export class MainpageComponent implements OnInit {
  private productService = inject(ProductService);
  private router = inject(Router);
  private discountService = inject(DiscountService);

  discountProducts: Product[] = [];
  top50Products: Product[] = [];
  newProducts: Product[] = [];
  loading: boolean = true;
  loadingNew: boolean = true;

  ngOnInit(): void {
    this.loadDiscountProducts();
    this.loadTop50Products();
    this.loadNewProducts();
  }

  loadDiscountProducts(): void {
    this.productService.getAllProducts().subscribe({
      next: (products) => {
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

        this.discountProducts = shuffled.slice(0, 4);
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

        this.top50Products = shuffled.slice(0, 4);
      },
      error: (err) => {
        console.error('Error loading Top50 products:', err);
      }
    });
  }

  loadNewProducts(): void {
    this.productService.getAllProducts().subscribe({
      next: (products) => {
        // Rendezés createdAt szerint (legújabb elöl)
        const sorted = [...products].sort((a, b) => {
          const dateA = new Date(a.createdAt || 0).getTime();
          const dateB = new Date(b.createdAt || 0).getTime();
          return dateB - dateA;
        });

        this.newProducts = sorted.slice(0, 4);
        this.loadingNew = false;
      },
      error: (err) => {
        console.error('Error loading new products:', err);
        this.loadingNew = false;
      }
    });
  }
}