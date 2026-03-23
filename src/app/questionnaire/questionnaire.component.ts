import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { HttpClient } from '@angular/common/http';
import { HeaderComponent } from "../header/header.component";
import { FooterComponent } from "../footer/footer.component";

interface Game {
  id: number;
  name: string;
  gameType: string;
  requirementLevel: number;
  description: string;
}

interface Configuration {
  id: number;
  name: string;
  description: string;
  budgetMin: number;
  budgetMax: number;
  useCase: string;
  gameTypes: string;
  requirementLevel: number;
  totalPrice: number;
  isFeatured: number;
}

interface ConfigProduct {
  configProductId: number;
  componentType: string;
  quantity: number;
  isRequired: number;
  productId: number;
  productName: string;
  productDescription: string;
  price: number;
  stock: number;
  imageUrl: string;
  categoryName: string;
  brandName: string;
  subtotal: number;
  inStock: number;
}

@Component({
  selector: 'app-questionnaire',
  standalone: true,
  imports: [CommonModule, FormsModule, HeaderComponent, FooterComponent],
  templateUrl: './questionnaire.component.html',
  styleUrl: './questionnaire.component.css'
})
export class QuestionnaireComponent implements OnInit {
  // API base URL
  private apiUrl = 'http://127.0.0.1:8080/coreTech3-1.0-SNAPSHOT/webresources/questionnaire';

  // Wizard step tracking
  currentStep: number = 1;
  totalSteps: number = 4; // Max 4 steps for gaming flow

  // Step 1: Budget
  selectedBudget: string = '';
  budgetOptions = [
    { label: '200-350 ezer Ft', value: 'budget_low', min: 200000, max: 350000, iconPath: 'assets/icons/budget_low.png' },
    { label: '350-550 ezer Ft', value: 'budget_mid', min: 350000, max: 550000, iconPath: 'assets/icons/budget_mid.png' },
    { label: '550 ezer Ft felett', value: 'budget_high', min: 550000, max: 2000000, iconPath: 'assets/icons/budget_high.png' }
  ];

  // Step 2: Use case
  selectedUseCase: string = '';
  useCaseOptions = [
    { label: 'Gaming', value: 'gaming', iconPath: 'assets/icons/gaming.png' },
    { label: 'Videószerkesztés', value: 'video_editing', iconPath: 'assets/icons/video_editing.png' },
    { label: 'Programozás', value: 'programming', iconPath: 'assets/icons/programming.png' },
    { label: 'Mindenmentes használat', value: 'all_purpose', iconPath: 'assets/icons/all_purpose.png' }
  ];

  // Step 3: Game types (conditional - only if gaming)
  selectedGameTypes: string[] = [];
  gameTypeGroups = [
    { type: 'solo_rpg', label: 'Egyedüli RPG', iconPath: 'assets/icons/solo_rpg.png' },
    { type: 'competitive_fps', label: 'Kompetitív FPS', iconPath: 'assets/icons/competitive_fps.png' },
    { type: 'aaa_games', label: 'AAA játékok', iconPath: 'assets/icons/aaa_games.png' },
    { type: 'indie_casual', label: 'Indie/Casual', iconPath: 'assets/icons/indie_casual.png' }
  ];

  // Step 4: Individual games (conditional - only if gaming and game types selected)
  selectedGameIds: number[] = [];
  availableGames: Game[] = [];
  filteredGames: Game[] = [];
  loadingGames: boolean = false;

  // Results
  showResults: boolean = false;
  loadingResults: boolean = false;
  recommendedConfigurations: Configuration[] = [];
  selectedConfigProducts: Map<number, ConfigProduct[]> = new Map();
  expandedConfigs: Set<number> = new Set();

  constructor(
    private http: HttpClient,
    private router: Router
  ) {}

  ngOnInit(): void {
    // Load all games when component initializes
    this.loadGames();
  }

  loadGames(): void {
    this.loadingGames = true;
    this.http.get<any>(`${this.apiUrl}/games`).subscribe({
      next: (response) => {
        if (response.status === 'Success') {
          this.availableGames = response.games;
          // Update filtered games if game types are already selected
          this.updateFilteredGames();
        }
        this.loadingGames = false;
      },
      error: (err) => {
        console.error('Error loading games:', err);
        this.loadingGames = false;
      }
    });
  }

  // Navigation
  nextStep(): void {
    if (this.currentStep === 1 && !this.selectedBudget) {
      alert('Kérlek válassz költségkeretet!');
      return;
    }

    if (this.currentStep === 2 && !this.selectedUseCase) {
      alert('Kérlek válassz felhasználási célt!');
      return;
    }

    // Skip step 3 & 4 if not gaming
    if (this.currentStep === 2 && this.selectedUseCase !== 'gaming') {
      this.submitQuestionnaire();
      return;
    }

    if (this.currentStep === 3 && this.selectedGameTypes.length === 0) {
      alert('Kérlek válassz legalább egy játék típust!');
      return;
    }

    if (this.currentStep < this.totalSteps) {
      this.currentStep++;
    } else {
      this.submitQuestionnaire();
    }
  }

  prevStep(): void {
    if (this.currentStep > 1) {
      this.currentStep--;
    }
  }

  goToStep(step: number): void {
    this.currentStep = step;
  }

  toggleGameType(gameType: string): void {
    const index = this.selectedGameTypes.indexOf(gameType);
    if (index > -1) {
      this.selectedGameTypes.splice(index, 1);
    } else {
      this.selectedGameTypes.push(gameType);
    }
    // Update filtered games when game types change
    this.updateFilteredGames();
  }

  isGameTypeSelected(gameType: string): boolean {
    return this.selectedGameTypes.includes(gameType);
  }

  updateFilteredGames(): void {
    if (this.selectedGameTypes.length === 0) {
      this.filteredGames = [];
    } else {
      this.filteredGames = this.availableGames.filter(game => 
        this.selectedGameTypes.includes(game.gameType)
      );
    }
    
    // Debug logging
    console.log('Selected game types:', this.selectedGameTypes);
    console.log('Available games:', this.availableGames.length);
    console.log('Filtered games:', this.filteredGames.length);
    console.log('Filtered games:', this.filteredGames);
  }

  toggleGame(gameId: number): void {
    const index = this.selectedGameIds.indexOf(gameId);
    if (index > -1) {
      this.selectedGameIds.splice(index, 1);
    } else {
      this.selectedGameIds.push(gameId);
    }
  }

  isGameSelected(gameId: number): boolean {
    return this.selectedGameIds.includes(gameId);
  }

  getSelectedBudgetRange(): { min: number, max: number } {
    const budget = this.budgetOptions.find(b => b.value === this.selectedBudget);
    return budget ? { min: budget.min, max: budget.max } : { min: 0, max: 0 };
  }

  submitQuestionnaire(): void {
    this.loadingResults = true;
    this.showResults = false;

    const budgetRange = this.getSelectedBudgetRange();
    
    // Get selected game IDs as comma-separated string
    let selectedGameIds = '';
    if (this.selectedUseCase === 'gaming' && this.selectedGameIds.length > 0) {
      selectedGameIds = this.selectedGameIds.join(',');
    }

    const requestBody = {
      budgetMin: budgetRange.min,
      budgetMax: budgetRange.max,
      useCase: this.selectedUseCase,
      selectedGameIds: selectedGameIds || undefined
    };

    this.http.post<any>(`${this.apiUrl}/recommend`, requestBody).subscribe({
      next: (response) => {
        if (response.status === 'Success') {
          this.recommendedConfigurations = response.configurations;
          this.showResults = true;
        }
        this.loadingResults = false;
      },
      error: (err) => {
        console.error('Error getting recommendations:', err);
        this.loadingResults = false;
        alert('Hiba történt az ajánlatok lekérdezése során.');
      }
    });
  }

  loadConfigProducts(configId: number): void {
    if (this.selectedConfigProducts.has(configId)) {
      // Already loaded, just toggle
      if (this.expandedConfigs.has(configId)) {
        this.expandedConfigs.delete(configId);
      } else {
        this.expandedConfigs.add(configId);
      }
      return;
    }

    // Load products
    this.http.get<any>(`${this.apiUrl}/configurations/${configId}/products`).subscribe({
      next: (response) => {
        if (response.status === 'Success') {
          this.selectedConfigProducts.set(configId, response.products);
          this.expandedConfigs.add(configId);
        }
      },
      error: (err) => {
        console.error('Error loading config products:', err);
      }
    });
  }

  isConfigExpanded(configId: number): boolean {
    return this.expandedConfigs.has(configId);
  }

  getConfigProducts(configId: number): ConfigProduct[] {
    return this.selectedConfigProducts.get(configId) || [];
  }

  resetQuestionnaire(): void {
    this.currentStep = 1;
    this.selectedBudget = '';
    this.selectedUseCase = '';
    this.selectedGameTypes = [];
    this.selectedGameIds = [];
    this.filteredGames = [];
    this.showResults = false;
    this.recommendedConfigurations = [];
    this.selectedConfigProducts.clear();
    this.expandedConfigs.clear();
  }

  formatPrice(price: number): string {
    return new Intl.NumberFormat('hu-HU').format(price) + ' Ft';
  }

  getGameTypeName(gameType: string): string {
    const typeNames: { [key: string]: string } = {
      'solo_rpg': 'Solo RPG',
      'competitive_fps': 'Kompetitív FPS',
      'aaa_games': 'AAA játék',
      'indie_casual': 'Indie/Casual'
    };
    return typeNames[gameType] || gameType;
  }
}