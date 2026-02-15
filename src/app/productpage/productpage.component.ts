import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router } from '@angular/router';
import { ProductService, Product } from '../services/product.service';
import { ProductcardComponent } from '../productcard/productcard.component';
import { FooterComponent } from "../footer/footer.component";
import { HeaderComponent } from "../header/header.component";
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-productpage',
  standalone: true,
  imports: [CommonModule, ProductcardComponent, FooterComponent, HeaderComponent, FormsModule],
  templateUrl: './productpage.component.html',
  styleUrl: './productpage.component.css',
})
export class ProductpageComponent implements OnInit {
  products: Product[] = [];
  filteredProducts: Product[] = [];
  loading: boolean = true;
  error: string | null = null;

  // Category info
  categoryId: number | null = null;
  categoryName: string = 'Termékek';
  productCount: number = 0;

  // Search and filters
  searchQuery: string = '';
  selectedManufacturer: string = 'all';
  selectedSort: string = 'default';
  isGlobalSearch: boolean = false; // true if searching across all products

  // Available manufacturers
  manufacturers: string[] = [];

  // Category mapping
  categoryMap: { [key: number]: string } = {
    1: 'Videókártyák',
    2: 'Processzorok',
    3: 'Alaplapok',
    4: 'RAM',
    5: 'Tápegységek',
    6: 'SSD',
    7: 'HDD',
    8: 'Házak',
    9: 'Hűtők',
    11: 'Egerek',
    12: 'Billentyűzetek',
    13: 'Monitorok',
    14: 'Fejhallgatók',
    15: 'Egérpadok',
    16: 'Mikrofonok'
  };

  // Search keyword to category ID mapping (only for category keywords)
  categoryKeywords: { [key: string]: number } = {
    'videókártya': 1, 'videokartya': 1, 'videókártyák': 1, 'gpu': 1, 'grafikus': 1,
    'processzor': 2, 'processzorok': 2, 'cpu': 2,
    'alaplap': 3, 'alaplapok': 3, 'motherboard': 3,
    'ram': 4, 'memória': 4, 'memoria': 4, 'memória (ram)': 4,
    'tápegység': 5, 'tapegyseg': 5, 'tápegységek': 5, 'psu': 5,
    'ssd': 6,
    'hdd': 7, 'merevlemez': 7,
    'ház': 8, 'haz': 8, 'házak': 8, 'gépház': 8, 'gephaz': 8,
    'hűtő': 9, 'huto': 9, 'hűtők': 9, 'cooler': 9, 'hűtés': 9, 'hutes': 9,
    'egér': 11, 'eger': 11, 'egerek': 11, 'mouse': 11,
    'billentyűzet': 12, 'billentyuzet': 12, 'billentyűzetek': 12, 'keyboard': 12,
    'monitor': 13, 'monitorok': 13,
    'fejhallgató': 14, 'fejhallgato': 14, 'fejhallgatók': 14, 'headset': 14,
    'egérpad': 15, 'egerpad': 15, 'egérpadok': 15, 'mousepad': 15,
    'mikrofon': 16, 'mikrofonok': 16, 'microphone': 16, 'mic': 16
  };

  constructor(
    private productService: ProductService,
    private route: ActivatedRoute,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.route.queryParams.subscribe(params => {
      const searchParam = params['search'] || '';
      const categoryParam = params['category'] ? +params['category'] : null;
      
      this.searchQuery = searchParam;
      
      // Check if search is a category keyword
      const categoryFromSearch = this.getCategoryFromKeyword(searchParam);
      
      if (categoryParam) {
        // Category explicitly specified
        this.categoryId = categoryParam;
        this.isGlobalSearch = false;
        this.categoryName = this.categoryMap[this.categoryId] || 'Termékek';
      } else if (categoryFromSearch) {
        // Search matches a category keyword
        this.categoryId = categoryFromSearch;
        this.isGlobalSearch = false;
        this.categoryName = this.categoryMap[this.categoryId] || 'Termékek';
      } else if (searchParam) {
        // Search for a product name - search all products
        this.categoryId = null;
        this.isGlobalSearch = true;
        this.categoryName = `Keresés: "${searchParam}"`;
      } else {
        // Default - show all products or category 1
        this.categoryId = 1;
        this.isGlobalSearch = false;
        this.categoryName = this.categoryMap[1];
      }
      
      // Reset filters when search/category changes
      this.selectedManufacturer = 'all';
      this.selectedSort = 'default';
      
      this.loadProducts();
    });
  }

  getCategoryFromKeyword(search: string): number | null {
    if (!search) return null;
    const searchLower = search.toLowerCase().trim();
    return this.categoryKeywords[searchLower] || null;
  }

  loadProducts(): void {
    this.loading = true;
    this.error = null;

    if (this.isGlobalSearch) {
      // Search across all products
      this.productService.getAllProducts().subscribe({
        next: (data) => {
          this.products = data;
          this.extractManufacturers();
          this.applyFilters();
          this.loading = false;
        },
        error: (error) => {
          console.error('Error loading products:', error);
          this.error = 'Nem sikerült betölteni a termékeket';
          this.loading = false;
        }
      });
    } else if (this.categoryId) {
      // Load products by category
      this.productService.getProductsByCategoryId(this.categoryId).subscribe({
        next: (data) => {
          this.products = data;
          this.extractManufacturers();
          this.applyFilters();
          this.loading = false;
        },
        error: (error) => {
          console.error('Error loading products:', error);
          this.error = 'Nem sikerült betölteni a termékeket';
          this.loading = false;
        }
      });
    }
  }

  extractManufacturers(): void {
    const brandSet = new Set<string>();
    this.products.forEach(p => {
      if (p.brandId?.name) {
        brandSet.add(p.brandId.name);
      }
    });
    this.manufacturers = Array.from(brandSet).sort();
  }

  applyFilters(): void {
    let filtered = [...this.products];

    // Apply search filter for product names (when doing global search)
    if (this.searchQuery && this.searchQuery.trim() !== '') {
      const query = this.searchQuery.toLowerCase().trim();
      
      // Only filter by text if it's a global search (not a category keyword)
      if (this.isGlobalSearch) {
        filtered = filtered.filter(p => 
          p.name.toLowerCase().includes(query) ||
          (p.description && p.description.toLowerCase().includes(query)) ||
          (p.brandId?.name && p.brandId.name.toLowerCase().includes(query))
        );
      }
    }

    // Manufacturer filter
    if (this.selectedManufacturer !== 'all') {
      filtered = filtered.filter(p => p.brandId?.name === this.selectedManufacturer);
    }

    // Sorting
    switch (this.selectedSort) {
      case 'price-asc':
        filtered.sort((a, b) => a.pPrice - b.pPrice);
        break;
      case 'price-desc':
        filtered.sort((a, b) => b.pPrice - a.pPrice);
        break;
      case 'name-asc':
        filtered.sort((a, b) => a.name.localeCompare(b.name));
        break;
      case 'name-desc':
        filtered.sort((a, b) => b.name.localeCompare(a.name));
        break;
    }

    this.filteredProducts = filtered;
    this.productCount = filtered.length;
  }

  onCategoryChange(event: Event): void {
    const select = event.target as HTMLSelectElement;
    const newCategoryId = +select.value;
    
    // Clear search when manually changing category
    this.router.navigate(['/products'], { 
      queryParams: { category: newCategoryId } 
    });
  }

  onManufacturerChange(event: Event): void {
    const select = event.target as HTMLSelectElement;
    this.selectedManufacturer = select.value;
    this.applyFilters();
  }

  onSortChange(event: Event): void {
    const select = event.target as HTMLSelectElement;
    this.selectedSort = select.value;
    this.applyFilters();
  }

  clearFilters(): void {
    this.selectedManufacturer = 'all';
    this.selectedSort = 'default';
    this.searchQuery = '';
    
    // If was global search, go back to default category
    if (this.isGlobalSearch) {
      this.router.navigate(['/products'], { 
        queryParams: { category: 1 } 
      });
    } else {
      this.applyFilters();
    }
  }
}