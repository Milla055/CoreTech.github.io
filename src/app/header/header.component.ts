import { Component, HostListener, OnInit } from '@angular/core';
import { ShopmenuComponent } from "../shopmenu/shopmenu.component";
import { Router, RouterLink } from "@angular/router";
import { AuthService } from "../services/auth.service";
import { CartService } from "../services/cart.service";
import { CommonModule } from '@angular/common';
import { CartComponent } from "../cart/cart.component";

@Component({
  selector: 'app-header',
  templateUrl: './header.component.html',
  styleUrls: ['./header.component.css'],
  imports: [ShopmenuComponent, RouterLink, CommonModule, CartComponent],
})
export class HeaderComponent implements OnInit {
  loginPopup = false;
  shopMenu = false;
  cartOpen = false;
  username: string | null = null;
  cartCount: number = 0;

  searchQuery = '';
  showSuggestions = false;
  suggestions = [
    'Videókártya', 'Processzor', 'Memória (RAM)', 'Alaplap',
    'SSD', 'HDD', 'Hűtés', 'Tápegység', 'Gépház',
    'Egér', 'Billentyűzet', 'Monitor', 'Fejhallgató', 'Mikrofon'
  ];
  filteredSuggestions: string[] = [];
  suggestionsHtml = '';

  // Category keywords (only exact category names)
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
    private authService: AuthService,
    private cartService: CartService,
    private router: Router
  ) {}

  ngOnInit() {
    // Subscribe to user changes
    this.authService.currentUser$.subscribe(user => {
      const wasLoggedIn = !!this.username;
      this.username = user?.username || null;
      
      // If user logged out, clear the cart
      if (wasLoggedIn && !this.username) {
        this.cartService.clearCart();
      }
    });

    // Subscribe to cart changes
    this.cartService.cart$.subscribe(() => {
      this.cartCount = this.cartService.getCartCount();
    });

    // Check localStorage as fallback
    const savedUser = localStorage.getItem('user');
    if (savedUser && !this.username) {
      const user = JSON.parse(savedUser);
      this.username = user.username;
    }
  }

  toggleCart(): void {
    this.cartOpen = !this.cartOpen;
  }

  closeCart(): void {
    this.cartOpen = false;
  }

  navigateToProfile() {
    this.router.navigate(['/profile']);
  }

  logout() {
    this.cartService.clearCart();
    this.authService.logout();
    this.username = null;
    this.router.navigate(['/mainpage']);
  }

  toggleShopMenu(){ this.shopMenu = !this.shopMenu; }
  closeShopMenu(){ this.shopMenu = false; }

  onSearch(value: string){
    this.searchQuery = value;
    const q = value.trim().toLowerCase();
    if (!q) {
      this.filteredSuggestions = [];
      this.suggestionsHtml = '';
      this.showSuggestions = false;
      return;
    }
    this.filteredSuggestions = this.suggestions.filter(s => s.toLowerCase().includes(q)).slice(0, 6);
    this.buildSuggestionsHtml();
    this.showSuggestions = this.filteredSuggestions.length > 0;
  }

  openSearch(){
    this.showSuggestions = this.searchQuery.trim().length > 0 && this.filteredSuggestions.length > 0;
  }

  buildSuggestionsHtml(){
    this.suggestionsHtml = this.filteredSuggestions
      .map(s => `<div class="result-item" data-value="${this.escapeHtml(s)}">${this.escapeHtml(s)}</div>`)
      .join('');
  }

  onSuggestionClick(e: MouseEvent){
    const target = (e.target as HTMLElement).closest('.result-item') as HTMLElement | null;
    if (!target) return;
    const val = target.dataset['value'] || target.textContent || '';
    this.selectSuggestion(val);
  }

  selectSuggestion(s: string){
    this.searchQuery = s;
    this.showSuggestions = false;
    this.filteredSuggestions = [];
    this.suggestionsHtml = '';
    this.navigateToProductPage(s);
  }

  onSearchSubmit(event?: Event) {
    if (event) {
      event.preventDefault();
    }
    if (this.searchQuery.trim()) {
      this.navigateToProductPage(this.searchQuery);
      this.showSuggestions = false;
    }
  }

  getCategoryFromKeyword(search: string): number | null {
    if (!search) return null;
    const searchLower = search.toLowerCase().trim();
    return this.categoryKeywords[searchLower] || null;
  }

  navigateToProductPage(query: string) {
    const categoryId = this.getCategoryFromKeyword(query);
    
    if (categoryId) {
      // It's a category keyword - go to that category
      this.router.navigate(['/products'], {
        queryParams: {
          search: query,
          category: categoryId
        }
      });
    } else {
      // It's a product search - search all products
      this.router.navigate(['/products'], {
        queryParams: {
          search: query
        }
      });
    }
  }

  @HostListener('document:click')
  onDocumentClick(){
    this.showSuggestions = false;
  }

  private escapeHtml(str: string){
    return str.replace(/[&<>"']/g, (m) => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]!));
  }
}