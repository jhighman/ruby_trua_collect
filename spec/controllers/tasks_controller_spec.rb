require 'rails_helper'

RSpec.describe TasksController, type: :controller do
  describe "GET #index" do
    it "returns a successful response" do
      get :index
      expect(response).to be_successful
    end
    
    it "assigns @tasks" do
      task = create(:task)
      get :index
      expect(assigns(:tasks)).to eq([task])
    end
  end
  
  describe "GET #show" do
    it "returns a successful response" do
      task = create(:task)
      get :show, params: { id: task.id }
      expect(response).to be_successful
    end
    
    it "assigns the requested task to @task" do
      task = create(:task)
      get :show, params: { id: task.id }
      expect(assigns(:task)).to eq(task)
    end
  end
  
  describe "POST #create" do
    context "with valid parameters" do
      let(:valid_params) { { task: { title: "New Task", description: "Task description" } } }
      
      it "creates a new task" do
        expect {
          post :create, params: valid_params
        }.to change(Task, :count).by(1)
      end
      
      it "redirects to the created task" do
        post :create, params: valid_params
        expect(response).to redirect_to(Task.last)
      end
    end
    
    context "with invalid parameters" do
      let(:invalid_params) { { task: { title: "", description: "Task description" } } }
      
      it "does not create a new task" do
        expect {
          post :create, params: invalid_params
        }.to_not change(Task, :count)
      end
      
      it "renders the new template" do
        post :create, params: invalid_params
        expect(response).to render_template(:new)
      end
    end
  end
end