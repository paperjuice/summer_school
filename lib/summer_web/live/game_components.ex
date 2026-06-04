defmodule SummerWeb.GameComponents do
  use Phoenix.Component

  attr :score, :integer, required: true

  def score_banner(assigns) do
    ~H"""
    <div class="player-score-bar">
      <div class="player-identity">
        <div class="player-avatar">MK</div>
        <div>
          <div class="player-name">Inspector Dragos</div>
          <div class="player-role">Senior Postal Officer</div>
        </div>
      </div>
      <div class="score-display">
        <span class="score-label">Score</span>
        <span class="score-value">{@score}</span>
        <span class="score-unit">pts</span>
      </div>
    </div>
    """
  end

  def match_time_remaining(assigns) do
    ~H"""
    <div class="card-timer-section">
      <span class="card-timer-label">Match time remaining</span>
      <div id="timer-track" class="card-timer-track" phx-update="ignore">
        <div class="card-timer-fill" style="width: 100%;"></div>
      </div>
      <span class="card-timer-seconds">300s</span>
    </div>
    """
  end

  attr :package, :map, required: true
  attr :timestamp, :integer, required: true
  attr :validation_result, :atom, required: true

  def package_inspection_form(assigns) do
    ~H"""
    <div class="card-reveal-wrapper">
      <%= case @validation_result do %>
        <% :correct -> %>
          <div class="stamp-result" id={"card-#{@timestamp}"}>
            <div class="stamp-mark approved">
              <span class="stamp-label">Approved</span>
              <span class="stamp-points">+1</span>
            </div>
          </div>
        <% :incorrect -> %>
          <div class="stamp-result" id={"card-#{@timestamp}"}>
            <div class="stamp-mark rejected">
              <span class="stamp-label">Rejected</span>
              <span class="stamp-points">−1</span>
            </div>
          </div>
        <% nil -> %>
          <div></div>
      <% end %>

      <div class="package-card">
        <div class="card-header">
          <div class="card-title-group">
            <div class="card-title">Package Inspection Form</div>
            <div class="card-id">PKG-{@timestamp}</div>
          </div>
          <div class="card-stamp">
            <span class="card-stamp-text">Postage</span>
            <span class="card-stamp-value">€4.50</span>
            <span class="card-stamp-text">Paid</span>
          </div>
        </div>

        <div class="package-fields">
          <div class="field">
            <div class="field-label">Package Type</div>
            <div class="field-value type-badge">{String.capitalize("#{@package.type}")}</div>
          </div>
          <div class="field">
            <div class="field-label">Weight</div>
            <div class="field-value">{@package.weight}g</div>
          </div>
          <div class="field">
            <div class="field-label">Destination</div>
            <div class="field-value">{String.capitalize("#{@package.destination}")}</div>
          </div>
          <div class="field">
            <div class="field-label">Shipping Class</div>
            <div class="field-value">{String.capitalize("#{@package.shipping_class}")}</div>
          </div>
          <div class="field">
            <div class="field-label">Declared Value</div>
            <div class="field-value">{@package.declared_value}</div>
          </div>
        </div>

        <div class="package-checks">
          <span :if={@package.has_customs_form} class="check-tag has">
            <span class="check-dot"></span> Customs Form
          </span>
          <span :if={@package.has_insurance} class="check-tag has">
            <span class="check-dot"></span> Insurance
          </span>
          <span :if={@package.has_fragile_sticker} class="check-tag has">
            <span class="check-dot"></span> Fragile Sticker
          </span>
        </div>

        <div class="card-actions">
          <button phx-click="decline" class="btn btn-decline">
            <span class="btn-icon">✕</span> Decline
          </button>
          <button phx-click="approve" class="btn btn-approve">
            <span class="btn-icon">✓</span> Approve
          </button>
        </div>
      </div>
    </div>
    """
  end

  attr :rule_descriptions, :list, required: true

  def postal_regulations(assigns) do
    ~H"""
    <div class="rules-reference">
      <div class="rules-header">
        <span class="rules-title">Postal Regulations</span>
      </div>
      <%= for {desc, index} <- Enum.with_index(@rule_descriptions) do %>
        <div class="rules-list">
          <div class="rule-item">
            <span class="rule-number">{index + 1}</span><span>{desc}</span>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
